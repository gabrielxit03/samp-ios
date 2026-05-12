#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include "../include/samp.h"

// Opcodes do protocolo SA-MP 0.3.7
#define PACKET_CONNECT          0x06
#define PACKET_DISCONNECT       0x59
#define PACKET_PLAYER_SYNC      0xA9
#define PACKET_BULLET_SYNC      0xA1
#define PACKET_VEHICLE_SYNC     0x8C
#define PACKET_CHAT_MESSAGE     0x62
#define PACKET_SPAWN            0x34

@interface SAMPNetwork ()
@property (nonatomic) int socket;
@property (nonatomic) BOOL conectado;
@property (nonatomic, strong) NSString *ipAtual;
@property (nonatomic) int portaAtual;
@property (nonatomic, strong) NSString *nomeAtual;
@property (nonatomic, strong) dispatch_queue_t filaRede;
@property (nonatomic) struct sockaddr_in enderecoServidor;
@end

@implementation SAMPNetwork

+ (instancetype)shared {
    static SAMPNetwork *instancia = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        instancia = [[SAMPNetwork alloc] init];
    });
    return instancia;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.socket = -1;
        self.conectado = NO;
        self.filaRede = dispatch_queue_create(
            "com.sampios.network", 
            DISPATCH_QUEUE_SERIAL
        );
    }
    return self;
}

// Conectar ao servidor SA-MP
- (void)conectar:(NSString*)ip porta:(int)porta nome:(NSString*)nome {
    self.ipAtual = ip;
    self.portaAtual = porta;
    self.nomeAtual = nome;
    
    dispatch_async(self.filaRede, ^{
        // Criar socket UDP
        self.socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
        if (self.socket < 0) {
            NSLog(@"[SAMP-iOS] Erro ao criar socket!");
            return;
        }
        
        // Configurar endereço do servidor
        memset(&self->_enderecoServidor, 0, sizeof(self->_enderecoServidor));
        self->_enderecoServidor.sin_family = AF_INET;
        self->_enderecoServidor.sin_port = htons(porta);
        inet_pton(AF_INET, [ip UTF8String], &self->_enderecoServidor.sin_addr);
        
        // Timeout de 5 segundos
        struct timeval timeout;
        timeout.tv_sec = 5;
        timeout.tv_usec = 0;
        setsockopt(self.socket, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
        
        NSLog(@"[SAMP-iOS] Conectando em %@:%d...", ip, porta);
        
        // Enviar pacote de conexão SA-MP
        [self enviarPacoteConexao];
        
        // Iniciar loop de recebimento
        [self iniciarRecepcao];
    });
}

// Montar e enviar pacote de conexão SA-MP 0.3.7
- (void)enviarPacoteConexao {
    // Formato do pacote SA-MP:
    // "SAMP" + IP(4 bytes) + Porta(2 bytes) + Opcode(1 byte) + Dados
    
    uint8_t pacote[256];
    int pos = 0;
    
    // Header "SAMP"
    pacote[pos++] = 'S';
    pacote[pos++] = 'A';
    pacote[pos++] = 'M';
    pacote[pos++] = 'P';
    
    // IP do servidor (4 bytes)
    uint32_t ip = self->_enderecoServidor.sin_addr.s_addr;
    memcpy(&pacote[pos], &ip, 4);
    pos += 4;
    
    // Porta (2 bytes)
    uint16_t porta = htons(self.portaAtual);
    memcpy(&pacote[pos], &porta, 2);
    pos += 2;
    
    // Opcode de conexão
    pacote[pos++] = PACKET_CONNECT;
    
    // Versão do cliente SA-MP
    uint16_t versao = 4057; // 0.3.7
    memcpy(&pacote[pos], &versao, 2);
    pos += 2;
    
    // Mod (0 = não mod, 1 = mod)
    pacote[pos++] = 0;
    
    // Tamanho do nome
    const char *nome = [self.nomeAtual UTF8String];
    uint8_t tamNome = strlen(nome);
    pacote[pos++] = tamNome;
    memcpy(&pacote[pos], nome, tamNome);
    pos += tamNome;
    
    // Senha (vazia)
    pacote[pos++] = 0;
    
    // Enviar
    sendto(
        self.socket, 
        pacote, pos, 0,
        (struct sockaddr*)&self->_enderecoServidor, 
        sizeof(self->_enderecoServidor)
    );
    
    NSLog(@"[SAMP-iOS] Pacote de conexão enviado!");
}

// Loop de recebimento de pacotes
- (void)iniciarRecepcao {
    uint8_t buffer[4096];
    struct sockaddr_in endRemetente;
    socklen_t tamEndereco = sizeof(endRemetente);
    
    while (self.socket >= 0) {
        ssize_t bytesRecebidos = recvfrom(
            self.socket,
            buffer, sizeof(buffer), 0,
            (struct sockaddr*)&endRemetente,
            &tamEndereco
        );
        
        if (bytesRecebidos < 0) {
            if (!self.conectado) {
                NSLog(@"[SAMP-iOS] Timeout - servidor não respondeu");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[SAMPHUD shared] adicionarMensagem:@"Servidor não respondeu!" 
                                                    cor:0xFF0000FF];
                });
            }
            continue;
        }
        
        // Processar pacote recebido
        [self processarPacote:buffer tamanho:bytesRecebidos];
    }
}

// Processar pacotes recebidos do servidor
- (void)processarPacote:(uint8_t*)dados tamanho:(ssize_t)tamanho {
    if (tamanho < 11) return;
    
    // Verificar header SA-MP
    if (dados[0] != 'S' || dados[1] != 'A' || 
        dados[2] != 'M' || dados[3] != 'P') return;
    
    uint8_t opcode = dados[10];
    
    switch (opcode) {
        case PACKET_CONNECT:
            NSLog(@"[SAMP-iOS] Conectado ao servidor!");
            self.conectado = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[SAMPHUD shared] adicionarMensagem:@"Conectado ao servidor!" 
                                                cor:0x00FF00FF];
            });
            break;
            
        case PACKET_DISCONNECT:
            NSLog(@"[SAMP-iOS] Desconectado do servidor!");
            self.conectado = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[SAMPHUD shared] adicionarMensagem:@"Desconectado!" 
                                                cor:0xFF0000FF];
            });
            break;
            
        case PACKET_CHAT_MESSAGE:
            // Processar mensagem de chat
            if (tamanho > 12) {
                NSString *msg = [NSString stringWithUTF8String:(char*)&dados[11]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[SAMPHUD shared] adicionarMensagem:msg cor:0xFFFFFFFF];
                });
            }
            break;
            
        default:
            break;
    }
}

// Enviar mensagem de chat
- (void)enviarChat:(NSString*)mensagem {
    if (!self.conectado) return;
    
    uint8_t pacote[256];
    int pos = 0;
    
    // Header SA-MP
    pacote[pos++] = 'S';
    pacote[pos++] = 'A';
    pacote[pos++] = 'M';
    pacote[pos++] = 'P';
    
    // IP e porta
    uint32_t ip = self->_enderecoServidor.sin_addr.s_addr;
    memcpy(&pacote[pos], &ip, 4); pos += 4;
    uint16_t porta = htons(self.portaAtual);
    memcpy(&pacote[pos], &porta, 2); pos += 2;
    
    // Opcode chat
    pacote[pos++] = PACKET_CHAT_MESSAGE;
    
    // Mensagem
    const char *texto = [mensagem UTF8String];
    uint8_t tam = strlen(texto);
    pacote[pos++] = tam;
    memcpy(&pacote[pos], texto, tam);
    pos += tam;
    
    sendto(self.socket, pacote, pos, 0,
           (struct sockaddr*)&self->_enderecoServidor,
           sizeof(self->_enderecoServidor));
}

- (void)desconectar {
    self.conectado = NO;
    if (self.socket >= 0) {
        close(self.socket);
        self.socket = -1;
    }
}

- (BOOL)estaConectado {
    return self.conectado;
}

@end
