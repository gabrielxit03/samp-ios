#pragma once
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// Versão do mod
#define SAMP_VERSION "0.1.0"
#define SAMP_PROTOCOL 37 // SA-MP 0.3.7

// Porta padrão SA-MP
#define SAMP_PORT 7777

// Máximo de jogadores
#define MAX_PLAYERS 1000

// Estrutura de um jogador conectado
typedef struct {
    int     id;
    char    nome[25];
    float   posX;
    float   posY;
    float   posZ;
    float   rotacao;
    int     vida;
    int     colete;
    bool    conectado;
    bool    visivel;
} SAMPJogador;

// Estrutura de mensagem do chat
typedef struct {
    char    texto[144];
    uint32_t cor;
    long    timestamp;
} SAMPMensagem;

// Forward declarations
@interface SAMPMenu : NSObject
+ (instancetype)shared;
- (void)mostrar;
@end

@interface SAMPNetwork : NSObject
+ (instancetype)shared;
- (void)conectar:(NSString*)ip porta:(int)porta nome:(NSString*)nome;
- (void)desconectar;
- (BOOL)estaConectado;
@end

@interface SAMPHUD : NSObject
+ (instancetype)shared;
- (void)iniciar;
- (void)parar;
- (void)adicionarMensagem:(NSString*)texto cor:(uint32_t)cor;
@end
