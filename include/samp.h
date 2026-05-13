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
    float   posX, posY, posZ, rotacao;
    int     vida, colete;
    bool    conectado, visivel;
} SAMPJogador;

typedef struct {
    char     texto[144];
    uint32_t cor;
    long     timestamp;
} SAMPMensagem;

// Helper iOS 13+ para pegar janela
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

// ── SAMPMenu ──────────────────────────────
@interface SAMPMenu : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITextField   *campoNome;
@property (nonatomic, strong) UITextField   *campoIP;
@property (nonatomic, strong) UITextField   *campoPorta;
@property (nonatomic, strong) UITableView   *listaServidores;
@property (nonatomic, strong) NSMutableArray *servidores;
+ (instancetype)shared;
- (void)mostrar;
@end

// ── SAMPNetwork ───────────────────────────
@interface SAMPNetwork : NSObject
+ (instancetype)shared;
- (void)conectar:(NSString*)ip porta:(int)porta nome:(NSString*)nome;
- (void)desconectar;
- (BOOL)estaConectado;
- (void)enviarChat:(NSString*)mensagem;
@end

// ── SAMPHUD ───────────────────────────────
@interface SAMPHUD : NSObject
+ (instancetype)shared;
- (void)iniciar;
- (void)parar;
- (void)adicionarMensagem:(NSString*)texto cor:(uint32_t)cor;
@end
