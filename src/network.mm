#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include "../include/samp.h"

// ── RakNet / SA-MP 0.3.7 ──────────────────────────────────────────
// O SA-MP usa RakNet por baixo dos panos.
// O primeiro pacote é um "Offline Ping" para verificar se o servidor existe,
// depois vem o "Open Connection Request" e finalmente o join.

// IDs de pacotes RakNet usados pelo SA-MP
#define ID_OPEN_CONNECTION_REQUEST      0x05
#define ID_OPEN_CONNECTION_REPLY        0x06
#define ID_CONNECTION_REQUEST           0x09
#define ID_CONNECTION_REQUEST_ACCEPTED  0x10
#define ID_NEW_INCOMING_CONNECTION      0x11
#define ID_DISCONNECTION_NOTIFICATION   0x15
#define ID_CONNECTION_LOST              0x16
#define ID_CONNECTION_BANNED            0x17
#define ID_INVALID_PASSWORD             0x1B
#define ID_DOWNLOAD_PROGRESS            0x1E
#define ID_USER_PACKET_ENUM             0x86

// Pacotes específicos SA-MP
#define PACKET_AUTH_KEY                 0x01
#define PACKET_CLIENT_JOIN              0x06
#define PACKET_CHAT_MESSAGE             0x62
#define PACKET_PLAYER_SYNC              0xA9

@interface SAMPNetwork ()
@property (nonatomic) int sock;
@property (nonatomic) BOOL conectado;
@property (nonatomic) BOOL rodando;
@property (nonatomic, strong) NSString *ipAtual;
@property (nonatomic) int portaAtual;
@property (nonatomic, strong) NSString *nomeAtual;
@property (nonatomic, strong) dispatch_queue_t filaRede;
@property (nonatomic) struct sockaddr_in endServidor;
@property (nonatomic) uint16_t mtuSize;
@property (nonatomic) uint32_t clientKey;
@end

@implementation SAMPNetwork

+ (instancetype)shared {
    static SAMPNetwork *i = nil;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ i = [[SAMPNetwork alloc] init]; });
    return i;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sock = -1;
        self.conectado = NO;
        self.rodando = NO;
        self.mtuSize = 576;
        self.clientKey = arc4random();
        self.filaRede = dispatch_queue_create("samp.net", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

// ── Resolver hostname ─────────────────────────────────────────────
- (NSString*)resolverHost:(NSString*)host {
    struct addrinfo hints, *res;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_DGRAM;
    if (getaddrinfo([host UTF8String], NULL, &hints, &res) == 0) {
        char ip[INET_ADDRSTRLEN];
        struct sockaddr_in *addr = (struct sockaddr_in*)res->ai_addr;
        inet_ntop(AF_INET, &addr->sin_addr, ip, sizeof(ip));
        freeaddrinfo(res);
        return [NSString stringWithUTF8String:ip];
    }
    return host;
}

// ── Iniciar conexão ───────────────────────────────────────────────
- (void)conectar:(NSString*)ip porta:(int)porta nome:(NSString*)nome {
    if (self.rodando) [self desconectar];
    self.ipAtual   = ip;
    self.portaAtual = porta;
    self.nomeAtual  = nome;
    self.rodando    = YES;

    dispatch_async(self.filaRede, ^{
        // Resolver hostname para IP
        NSString *ipReal = [self resolverHost:ip];
        NSLog(@"[SAMP] Conectando: %@ -> %@:%d", ip, ipReal, porta);
        [self notificar:[NSString stringWithFormat:@"Conectando em %@...", ip]
                    cor:0xFFFF00FF];

        // Criar socket UDP
        self.sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
        if (self.sock < 0) {
            [self notificar:@"Erro: não foi possível criar socket" cor:0xFF0000FF];
            return;
        }

        // Configurar endereço do servidor
        memset(&self->_endServidor, 0, sizeof(self->_endServidor));
        self->_endServidor.sin_family = AF_INET;
        self->_endServidor.sin_port   = htons(porta);
        inet_pton(AF_INET, [ipReal UTF8String], &self->_endServidor.sin_addr);

        // Timeout
        struct timeval tv = {8, 0};
        setsockopt(self.sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

        // Passo 1: Enviar ping SA-MP para verificar servidor
        if (![self enviarPingSAMP]) {
            [self notificar:@"Servidor não encontrado!" cor:0xFF0000FF];
            [self fecharSocket];
            return;
        }

        // Passo 2: Open Connection Request (RakNet)
        [self enviarOpenConnectionRequest];

        // Iniciar loop de recebimento
        [self loopRecepcao];
    });
}

// ── Ping SA-MP (verifica se servidor existe) ──────────────────────
- (BOOL)enviarPingSAMP {
    // Formato: "SAMP" + IP(4) + Porta(2) + 'p' (ping)
    uint8_t pkt[11];
    pkt[0]='S'; pkt[1]='A'; pkt[2]='M'; pkt[3]='P';
    memcpy(&pkt[4], &self->_endServidor.sin_addr.s_addr, 4);
    uint16_t p = htons(self.portaAtual);
    memcpy(&pkt[8], &p, 2);
    pkt[10] = 'p';

    sendto(self.sock, pkt, 11, 0,
           (struct sockaddr*)&self->_endServidor, sizeof(self->_endServidor));

    // Aguardar resposta do ping
    uint8_t buf[512];
    struct sockaddr_in rem; socklen_t remLen = sizeof(rem);
    ssize_t bytes = recvfrom(self.sock, buf, sizeof(buf), 0,
                              (struct sockaddr*)&rem, &remLen);

    if (bytes >= 11 && buf[0]=='S' && buf[1]=='A' && buf[2]=='M' && buf[3]=='P') {
        NSLog(@"[SAMP] Servidor respondeu ao ping!");
        [self notificar:@"Servidor encontrado! Conectando..." cor:0x00FF00FF];
        return YES;
    }
    return NO;
}

// ── RakNet Open Connection Request ────────────────────────────────
- (void)enviarOpenConnectionRequest {
    uint8_t pkt[128];
    int pos = 0;

    pkt[pos++] = ID_OPEN_CONNECTION_REQUEST; // 0x05

    // Magic RakNet (16 bytes)
    const uint8_t magic[16] = {
        0x00,0xFF,0xFF,0x00,0xFE,0xFE,0xFE,0xFE,
        0xFD,0xFD,0xFD,0xFD,0x12,0x34,0x56,0x78
    };
    memcpy(&pkt[pos], magic, 16); pos += 16;

    pkt[pos++] = 0; // versão RakNet = 0

    // MTU size
    uint16_t mtu = htons(self.mtuSize);
    memcpy(&pkt[pos], &mtu, 2); pos += 2;

    sendto(self.sock, pkt, pos, 0,
           (struct sockaddr*)&self->_endServidor, sizeof(self->_endServidor));
    NSLog(@"[SAMP] Open Connection Request enviado");
}

// ── RakNet Connection Request ─────────────────────────────────────
- (void)enviarConnectionRequest {
    uint8_t pkt[128];
    int pos = 0;

    pkt[pos++] = ID_CONNECTION_REQUEST; // 0x09

    // Senha (vazia = 4 zeros)
    uint32_t senha = 0;
    memcpy(&pkt[pos], &senha, 4); pos += 4;

    // Timestamp
    uint64_t ts = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    memcpy(&pkt[pos], &ts, 8); pos += 8;

    sendto(self.sock, pkt, pos, 0,
           (struct sockaddr*)&self->_endServidor, sizeof(self->_endServidor));
    NSLog(@"[SAMP] Connection Request enviado");
}

// ── Pacote de join SA-MP ──────────────────────────────────────────
- (void)enviarJoinServidor {
    uint8_t pkt[256];
    int pos = 0;

    // Header RakNet encapsulado
    pkt[pos++] = 0x80; // ID_USER_PACKET - encapsulado
    pkt[pos++] = 0x00; // sequence number
    pkt[pos++] = 0x00;
    pkt[pos++] = 0x00;

    // Opcode SA-MP join
    pkt[pos++] = PACKET_CLIENT_JOIN;

    // Versão SA-MP 0.3.7 = 4057
    uint16_t versao = 4057;
    memcpy(&pkt[pos], &versao, 2); pos += 2;

    // Mod
    pkt[pos++] = 0;

    // Nome do jogador
    const char *nome = [self.nomeAtual UTF8String];
    uint8_t tamNome = (uint8_t)MIN(strlen(nome), 24);
    pkt[pos++] = tamNome;
    memcpy(&pkt[pos], nome, tamNome); pos += tamNome;

    // Senha (vazia)
    pkt[pos++] = 0;

    sendto(self.sock, pkt, pos, 0,
           (struct sockaddr*)&self->_endServidor, sizeof(self->_endServidor));
    NSLog(@"[SAMP] Join enviado como: %@", self.nomeAtual);
}

// ── Loop de recebimento ───────────────────────────────────────────
- (void)loopRecepcao {
    uint8_t buf[4096];
    struct sockaddr_in rem;
    socklen_t remLen = sizeof(rem);

    while (self.rodando && self.sock >= 0) {
        ssize_t bytes = recvfrom(self.sock, buf, sizeof(buf), 0,
                                  (struct sockaddr*)&rem, &remLen);
        if (bytes > 0) {
            [self processarPacote:buf tamanho:bytes];
        }
    }
}

// ── Processar pacotes recebidos ───────────────────────────────────
- (void)processarPacote:(uint8_t*)d tamanho:(ssize_t)tam {
    if (tam < 1) return;
    uint8_t id = d[0];
    NSLog(@"[SAMP] Pacote ID: 0x%02X (%zd bytes)", id, tam);

    switch (id) {
        case ID_OPEN_CONNECTION_REPLY: // 0x06
            NSLog(@"[SAMP] Open Connection Reply recebido!");
            [self enviarConnectionRequest];
            break;

        case ID_CONNECTION_REQUEST_ACCEPTED: // 0x10
            NSLog(@"[SAMP] Conexão aceita pelo servidor!");
            self.conectado = YES;
            [self enviarJoinServidor];
            [self notificar:@"Conectado! Entrando no servidor..." cor:0x00FF00FF];
            break;

        case ID_NEW_INCOMING_CONNECTION: // 0x11
            NSLog(@"[SAMP] Nova conexão estabelecida!");
            break;

        case ID_DISCONNECTION_NOTIFICATION: // 0x15
        case ID_CONNECTION_LOST: // 0x16
            self.conectado = NO;
            [self notificar:@"Desconectado do servidor!" cor:0xFF4400FF];
            break;

        case ID_CONNECTION_BANNED: // 0x17
            self.conectado = NO;
            [self notificar:@"Você foi banido do servidor!" cor:0xFF0000FF];
            break;

        case ID_INVALID_PASSWORD: // 0x1B
            self.conectado = NO;
            [self notificar:@"Senha incorreta!" cor:0xFF0000FF];
            break;

        default:
            // Pacotes de jogo (chat, sync, etc)
            if (id == 0x84 || id == 0x86) {
                [self processarPacoteJogo:d tamanho:tam];
            }
            break;
    }
}

// ── Processar pacotes do jogo (chat, textdraws, etc) ─────────────
- (void)processarPacoteJogo:(uint8_t*)d tamanho:(ssize_t)tam {
    if (tam < 2) return;
    uint8_t opcode = d[1];

    switch (opcode) {
        case 0x62: { // Chat message
            if (tam > 6) {
                uint8_t playerID = d[2];
                uint8_t tamMsg = d[3];
                if (tam >= 4 + tamMsg) {
                    NSString *msg = [[NSString alloc]
                        initWithBytes:&d[4]
                        length:tamMsg
                        encoding:NSUTF8StringEncoding];
                    [self notificar:msg cor:0xFFFFFFFF];
                }
            }
            break;
        }

        default:
            break;
    }
}

// ── Enviar chat ───────────────────────────────────────────────────
- (void)enviarChat:(NSString*)msg {
    if (!self.conectado || self.sock < 0) return;
    uint8_t pkt[256];
    int pos = 0;
    pkt[pos++] = 0x80;
    pkt[pos++] = 0x00;
    pkt[pos++] = 0x00;
    pkt[pos++] = 0x00;
    pkt[pos++] = PACKET_CHAT_MESSAGE;
    const char *txt = [msg UTF8String];
    uint8_t tam = (uint8_t)MIN(strlen(txt), 143);
    pkt[pos++] = tam;
    memcpy(&pkt[pos], txt, tam); pos += tam;
    sendto(self.sock, pkt, pos, 0,
           (struct sockaddr*)&self->_endServidor, sizeof(self->_endServidor));
}

// ── Helpers ───────────────────────────────────────────────────────
- (void)notificar:(NSString*)msg cor:(uint32_t)cor {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[SAMPHUD shared] adicionarMensagem:msg cor:cor];
    });
}

- (void)fecharSocket {
    self.rodando = NO;
    if (self.sock >= 0) { close(self.sock); self.sock = -1; }
}

- (void)desconectar {
    self.conectado = NO;
    [self fecharSocket];
}

- (BOOL)estaConectado { return self.conectado; }

@end
