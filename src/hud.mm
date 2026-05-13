#import <UIKit/UIKit.h>
#include "../include/samp.h"

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
    static SAMPHUD *i = nil;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ i = [[SAMPHUD alloc] init]; });
    return i;
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
        UIWindow *janela = getJanela();
        [self configurarHUD:janela];
    });
}

- (void)configurarHUD:(UIWindow*)janela {
    CGFloat w = janela.bounds.size.width;
    CGFloat h = janela.bounds.size.height;

    // Área do chat
    self.viewChat = [[UIView alloc] initWithFrame:CGRectMake(5, h-200, w*0.6, 160)];
    self.viewChat.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    self.viewChat.layer.cornerRadius = 5;
    [janela addSubview:self.viewChat];

    for (int i = 0; i < MAX_MENSAGENS_CHAT; i++) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(5, i*15, self.viewChat.bounds.size.width-10, 14)];
        l.font = [UIFont systemFontOfSize:11];
        l.textColor = UIColor.whiteColor;
        l.text = @"";
        [self.viewChat addSubview:l];
        [self.labelsMensagens addObject:l];
    }

    // Input chat
    self.campoChatInput = [[UITextField alloc] initWithFrame:CGRectMake(5, h-35, w*0.6-60, 30)];
    self.campoChatInput.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    self.campoChatInput.textColor = UIColor.whiteColor;
    self.campoChatInput.font = [UIFont systemFontOfSize:12];
    self.campoChatInput.placeholder = @"Digite sua mensagem...";
    self.campoChatInput.hidden = YES;
    self.campoChatInput.layer.cornerRadius = 4;
    self.campoChatInput.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,8,0)];
    self.campoChatInput.leftViewMode = UITextFieldViewModeAlways;
    [janela addSubview:self.campoChatInput];

    // Botão T (abrir chat)
    self.btnChat = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.btnChat setTitle:@"T" forState:UIControlStateNormal];
    [self.btnChat setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.btnChat.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    self.btnChat.frame = CGRectMake(w*0.6-50, h-35, 45, 30);
    self.btnChat.layer.cornerRadius = 4;
    [self.btnChat addTarget:self action:@selector(toggleChat) forControlEvents:UIControlEventTouchUpInside];
    [janela addSubview:self.btnChat];

    // Botão enviar
    UIButton *btnEnviar = [UIButton buttonWithType:UIButtonTypeSystem];
    [btnEnviar setTitle:@"OK" forState:UIControlStateNormal];
    [btnEnviar setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btnEnviar.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:0.8];
    btnEnviar.frame = CGRectMake(w*0.6-5, h-35, 40, 30);
    btnEnviar.layer.cornerRadius = 4;
    [btnEnviar addTarget:self action:@selector(enviarMensagem) forControlEvents:UIControlEventTouchUpInside];
    [janela addSubview:btnEnviar];

    [self adicionarMensagem:@"SA-MP iOS carregado!" cor:0xFFFF00FF];
    [self adicionarMensagem:@"Bem vindo!" cor:0x00FF00FF];
}

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

- (void)enviarMensagem {
    NSString *texto = self.campoChatInput.text;
    if (texto.length == 0) return;
    [[SAMPNetwork shared] enviarChat:texto];
    [self adicionarMensagem:[NSString stringWithFormat:@"Você: %@", texto] cor:0xFFFFFFFF];
    self.campoChatInput.text = @"";
    [self toggleChat];
}

- (void)adicionarMensagem:(NSString*)texto cor:(uint32_t)cor {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mensagens addObject:@{@"texto": texto, @"cor": @(cor)}];
        while (self.mensagens.count > MAX_MENSAGENS_CHAT)
            [self.mensagens removeObjectAtIndex:0];
        for (int i = 0; i < (int)self.labelsMensagens.count; i++) {
            UILabel *l = self.labelsMensagens[i];
            if (i < (int)self.mensagens.count) {
                NSDictionary *m = self.mensagens[i];
                l.text = m[@"texto"];
                uint32_t c = [m[@"cor"] unsignedIntValue];
                l.textColor = [UIColor colorWithRed:((c>>24)&0xFF)/255.0
                                              green:((c>>16)&0xFF)/255.0
                                               blue:((c>>8) &0xFF)/255.0
                                              alpha:( c      &0xFF)/255.0];
            } else { l.text = @""; }
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
