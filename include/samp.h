#pragma once
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define SAMP_VERSION "0.1.0"
#define SAMP_PROTOCOL 37
#define SAMP_PORT 7777
#define MAX_PLAYERS 1000

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

typedef struct {
    char    texto[144];
    uint32_t cor;
    long    timestamp;
} SAMPMensagem;

// Helper para pegar janela atual (iOS 13+)
static inline UIWindow* getJanela() {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow) return w;
            }
        }
    }
    return nil;
}

@interface SAMPMenu : UIViewController <UITableViewDelegate, UITableViewDataSource>
+ (instancetype)shared;
- (void)mostrar;
@end

@interface SAMPNetwork : NSObject
+ (instancetype)shared;
- (void)conectar:(NSString*)ip porta:(int)porta nome:(NSString*)nome;
- (void)desconectar;
- (BOOL)estaConectado;
- (void)enviarChat:(NSString*)mensagem;
@end

@interface SAMPHUD : NSObject
+ (instancetype)shared;
- (void)iniciar;
- (void)parar;
- (void)adicionarMensagem:(NSString*)texto cor:(uint32_t)cor;
@end
