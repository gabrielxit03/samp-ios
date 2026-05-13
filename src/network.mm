#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include "../include/samp.h"

@interface SAMPNetwork ()
@property (nonatomic) int sock;
@property (nonatomic) BOOL conectado;
@property (nonatomic, strong) NSString *ipAtual;
@property (nonatomic) int portaAtual;
@property (nonatomic, strong) NSString *nomeAtual;
@property (nonatomic, strong) dispatch_queue_t filaRede;
@property (nonatomic) struct sockaddr_in endServidor;
@property (nonatomic) BOOL rodando;
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
        self.filaRede = dispatch_queue_create("samp.network", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

// Resolver hostname para IP
- (NSString*)resolverIP:(NSString*)host {
    struct hostent *he = gethostbyname([host UTF8String]);
    if (!he) return host;
    struct in_addr addr;
    memcpy(&addr, he->h_addr_list[0], sizeof(struct in_addr));
    return [NSString stringWithUTF8String:inet_ntoa(addr)];
}

- (void)conectar:(NSString*)ip porta:(int)porta nome:(NSString*)nome {
    // Desconectar se já conectado
    if (self.rodando) [self desconectar];

    self.ipAtual   = ip;
    self.portaAtual = porta;
    self.nomeAtual  = nome;
    self.rodando    = YES;

    dispatch_async(self.filaRede, ^{
        // Resolver hostname
        NSString *ipResolvido = [self resolverIP:ip];
        NSLog(@"[SAMP] Conectando em %@ (%@):%d como %@", ip, ipResolvido, porta, nome);

        // Criar socket UDP
        self.sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
        if (self.sock < 0) {
            [self notificar:@"Erro ao criar socket!" cor:0xFF0000FF];
            return;
        }

        // Configurar endereço
        memset(&self->_endServidor, 0, sizeof(self->_endServidor));
        self->_endServidor.sin_family = AF_INET;
        self->_endServidor.sin_port   = htons(porta);
        inet_pton(AF_INET, [ipResolvido UTF8String], &self->_endServidor.sin_addr);

        // Timeout de recebimento
        struct timeval tv = {5, 0};
        setsockopt(self.sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

        // Tentar conectar 3 vezes
        for (int tentativa = 0; tentativa < 3; tentativa++) {
            NSLog(@"[SAMP] Tentativa %d...", tentativa+1);
            [self enviarPacoteConexao];

            // Aguardar resposta
            uint8_t buf[4096];
            struct sockaddr_in remetente;
            socklen_t tamRem = sizeof(remetente);
            ssize_t bytes = recvfrom(self.sock, buf, sizeof(buf), 0,
                                     (struct sockaddr*)&remetente, &tamRem);
            if (bytes > 0) {
                [self processarPacote:buf tamanho:bytes];
                // Iniciar loop de recebimento contínuo
                [self loopRecepcao];
                return;
            }
        }

        // Falhou
        [self notificar:@"Servidor não respondeu! Verifique o IP." cor:0xFF4400FF];
        self.rodando = NO;
        close(self.sock);
        self.sock = -1;
    });
}

- (void)enviarPacoteConexao {
    // Pacote SA-MP 0.3.7
    // Formato: SAMP + IP(4) + Porta(2) + Opcode(1) + Versão(2) + Mod(1) + TamNome(1) + Nome + TamSenha(1)
    uint8_t pkt[256];
    int pos = 0;

    // Header
    pkt[pos++]='S'; pkt[pos++]='A'; pkt[pos++]='M'; pkt[pos++]='P';

    // IP em bytes
    uint32_t ip = self->_endServidor.sin_addr.s_addr;
    memcpy(&pkt[pos], &ip, 4); pos += 4;

    // Porta
    uint16_t porta = htons(self.portaAtual);
    memcpy(&pkt[pos], &porta, 2); pos += 2;

    // Opcode conexão = 'i'
    pkt[pos++] = 'i';

    // Versão SA-MP 0.3.7 = 4057
    uint16_t versao = 4057;
    memcpy(&pkt[pos], &versao, 2); pos += 2;

    // Mod
    pkt[pos++] = 0;

    // Nome
    const char *nome = [self.nomeAtual UTF8String];
    uint8_t tamNome = (uint8_t)MIN(strlen(nome), 24);
    pkt[pos++] = tamNome;
    memcpy(&pkt[pos], nome, tamNome); pos += tamNome;

    // Senha (vazia)
    pkt[pos++] = 0;

    sendto(self.sock, pkt, pos, 0,
           (struct sockaddr*)&self->_endServidor,
           sizeof(self->_endServidor));
}

- (void)loopRecepcao {
    uint8_t buf[4096];
    struct sockaddr_in rem;
    socklen_t tamRem = sizeof(rem);

    while (self.rodando && self.sock >= 0) {
        ssize_t bytes = recvfrom(self.sock, buf, sizeof(buf), 0,
                                  (struct sockaddr*)&rem, &tamRem);
        if (bytes > 0) [self processarPacote:buf tamanho:bytes];
    }
}

- (void)processarPacote:(uint8_t*)d tamanho:(ssize_t)tam {
    if (tam < 11) return;
    if (d[0]!='S'||d[1]!='A'||d[2]!='M'||d[3]!='P') return;

    uint8_t opcode = d[10];
    NSLog(@"[SAMP] Pacote recebido opcode: 0x%02X", opcode);

    switch (opcode) {
        case 'i': // Resposta de conexão
            NSLog(@"[SAMP] Conectado!");
            self.conectado = YES;
            [self notificar:@"Conectado ao servidor!" cor:0x00FF00FF];
            break;

        case 'd': // Desconexão
            self.conectado = NO;
            [self notificar:@"Desconectado do servidor!" cor:0xFF0000FF];
            break;

        default:
            break;
    }
}

- (void)enviarChat:(NSString*)msg {
    if (!self.conectado || self.sock < 0) return;
    uint8_t pkt[256];
    int pos = 0;
    pkt[pos++]='S'; pkt[pos++]='A'; pkt[pos++]='M'; pkt[pos++]='P';
    uint32_t ip = self->_endServidor.sin_addr.s_addr;
    memcpy(&pkt[pos], &ip, 4); pos += 4;
    uint16_t porta = htons(self.portaAtual);
    memcpy(&pkt[pos], &porta, 2); pos += 2;
    pkt[pos++] = 0x62; // chat
    const char *txt = [msg UTF8String];
    uint8_t tam = (uint8_t)MIN(strlen(txt), 143);
    pkt[pos++] = tam;
    memcpy(&pkt[pos], txt, tam); pos += tam;
    sendto(self.sock, pkt, pos, 0,
           (struct sockaddr*)&self->_endServidor,
           sizeof(self->_endServidor));
}

- (void)notificar:(NSString*)msg cor:(uint32_t)cor {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[SAMPHUD shared] adicionarMensagem:msg cor:cor];
    });
}

- (void)desconectar {
    self.rodando = NO;
    self.conectado = NO;
    if (self.sock >= 0) {
        close(self.sock);
        self.sock = -1;
    }
}

- (BOOL)estaConectado { return self.conectado; }

@end
