#import <UIKit/UIKit.h>
#include "../include/samp.h"

// Máximo de mensagens no chat
#define MAX_MENSAGENS_CHAT 10

@interface SAMPHUD ()
@property (nonatomic, strong) UIView *viewChat;
@property (nonatomic, strong) UITextField *campoChatInput;
@property (nonatomic, strong) UIButton *btnChat;
@property (nonatomic, strong) NSMutableArray *mensagens;
@property (nonatomic, strong) NSMutableArray *labelsMensagens;
@property (nonatomic) BOOL chatAberto;
@end

@implementation SAMPHUD

+ (instancetype)shared {
    static SAMPHUD *instancia = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        instancia = [[SAMPHUD alloc] init];
    });
    return instancia;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.mensagens = [NSMutableArray new];
        self.labelsMensagens = [NSMutableArray new];
        self.chatAberto = NO;
    }
    return self;
}

- (void)iniciar {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *janela = [UIApplication sharedApplication].keyWindow;
        [self configurarHUD:janela];
        NSLog(@"[SAMP-iOS] HUD iniciado!");
    });
}

- (void)configurarHUD:(UIWindow*)janela {
    CGFloat larguraTela = janela.bounds.size.width;
    CGFloat alturaTela = janela.bounds.size.height;
    
    // ─── ÁREA DO CHAT (canto inferior esquerdo) ───
    self.viewChat = [[UIView alloc] initWithFrame:CGRectMake(
        5, 
        alturaTela - 200, 
        larguraTela * 0.6, 
        160
    )];
    self.viewChat.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    self.viewChat.layer.cornerRadius = 5;
    [janela addSubview:self.viewChat];
    
    // Labels das mensagens
    for (int i = 0; i < MAX_MENSAGENS_CHAT; i++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(
            5, i * 15, 
            self.viewChat.bounds.size.width - 10, 
            14
        )];
        label.font = [UIFont systemFontOfSize:11];
        label.textColor = [UIColor whiteColor];
        label.text = @"";
        [self.viewChat addSubview:label];
        [self.labelsMensagens addObject:label];
    }
    
    // ─── INPUT DO CHAT ───
    self.campoChatInput = [[UITextField alloc] initWithFrame:CGRectMake(
        5, 
        alturaTela - 35, 
        larguraTela * 0.6 - 60, 
        30
    )];
    self.campoChatInput.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    self.campoChatInput.textColor = [UIColor whiteColor];
    self.campoChatInput.font = [UIFont systemFontOfSize:12];
    self.campoChatInput.placeholder = @"Digite sua mensagem...";
    self.campoChatInput.hidden = YES;
    self.campoChatInput.layer.cornerRadius = 4;
    self.campoChatInput.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,8,0)];
    self.campoChatInput.leftViewMode = UITextFieldViewModeAlways;
    [janela addSubview:self.campoChatInput];
    
    // Botão enviar chat
    self.btnChat = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.btnChat setTitle:@"T" forState:UIControlStateNormal];
    [self.btnChat setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.btnChat.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    self.btnChat.frame = CGRectMake(
        larguraTela * 0.6 - 50, 
        alturaTela - 35, 
        45, 30
    );
    self.btnChat.layer.cornerRadius = 4;
    [self.btnChat addTarget:self 
                     action:@selector(toggleChat) 
           forControlEvents:UIControlEventTouchUpInside];
    [janela addSubview:self.btnChat];
    
    // Botão enviar mensagem
    UIButton *btnEnviar = [UIButton buttonWithType:UIButtonTypeSystem];
    [btnEnviar setTitle:@"OK" forState:UIControlStateNormal];
    [btnEnviar setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnEnviar.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:0.8];
    btnEnviar.frame = CGRectMake(
        larguraTela * 0.6 - 5,
        alturaTela - 35,
        40, 30
    );
    btnEnviar.layer.cornerRadius = 4;
    btnEnviar.hidden = YES;
    [btnEnviar addTarget:self 
                  action:@selector(enviarMensagem) 
        forControlEvents:UIControlEventTouchUpInside];
    [janela addSubview:btnEnviar];
    
    // Mensagem de boas vindas
    [self adicionarMensagem:@"SA-MP iOS carregado!" cor:0xFFFF00FF];
    [self adicionarMensagem:@"Bem vindo ao servidor!" cor:0x00FF00FF];
}

// Abrir/fechar chat
- (void)toggleChat {
    self.chatAberto = !self.chatAberto;
    self.campoChatInput.hidden = !self.chatAberto;
    
    if (self.chatAberto) {
        [self.campoChatInput becomeFirstResponder];
        [self.btnChat setTitle:@"X" forState:UIControlStateNormal];
    } else {
        [self.campoChatInput resignFirstResponder];
        self.campoChatInput.text = @"";
        [self.btnChat setTitle:@"T" forState:UIControlStateNormal];
    }
}

// Enviar mensagem
- (void)enviarMensagem {
    NSString *texto = self.campoChatInput.text;
    if (texto.length == 0) return;
    
    [[SAMPNetwork shared] enviarChat:texto];
    [self adicionarMensagem:[NSString stringWithFormat:@"Você: %@", texto] 
                       cor:0xFFFFFFFF];
    
    self.campoChatInput.text = @"";
    [self toggleChat];
}

// Adicionar mensagem no chat
- (void)adicionarMensagem:(NSString*)texto cor:(uint32_t)cor {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Adicionar na lista
        [self.mensagens addObject:@{@"texto": texto, @"cor": @(cor)}];
        
        // Manter só as últimas MAX_MENSAGENS_CHAT
        while (self.mensagens.count > MAX_MENSAGENS_CHAT) {
            [self.mensagens removeObjectAtIndex:0];
        }
        
        // Atualizar labels na tela
        for (int i = 0; i < self.labelsMensagens.count; i++) {
            UILabel *label = self.labelsMensagens[i];
            if (i < self.mensagens.count) {
                NSDictionary *msg = self.mensagens[i];
                label.text = msg[@"texto"];
                
                // Converter cor RGBA para UIColor
                uint32_t c = [msg[@"cor"] unsignedIntValue];
                label.textColor = [UIColor 
                    colorWithRed:((c >> 24) & 0xFF) / 255.0
                           green:((c >> 16) & 0xFF) / 255.0
                            blue:((c >> 8)  & 0xFF) / 255.0
                           alpha:( c        & 0xFF) / 255.0];
            } else {
                label.text = @"";
            }
        }
    });
}

- (void)parar {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.viewChat removeFromSuperview];
        [self.campoChatInput removeFromSuperview];
        [self.btnChat removeFromSuperview];
    });
}

@end
