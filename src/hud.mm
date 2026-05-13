#import <UIKit/UIKit.h>
#include "../include/samp.h"

#define MAX_MENSAGENS_CHAT 8

@interface SAMPHUD ()
@property (nonatomic, strong) UIView *viewChat;
@property (nonatomic, strong) UIView *viewInput;
@property (nonatomic, strong) UITextField *campoChatInput;
@property (nonatomic, strong) UIButton *btnChat;
@property (nonatomic, strong) UIButton *btnEnviar;
@property (nonatomic, strong) NSMutableArray *mensagens;
@property (nonatomic, strong) NSMutableArray *labelsMensagens;
@property (nonatomic) BOOL chatAberto;
@property (nonatomic, strong) UIView *areaClique;
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
    CGFloat alturaMensagem = 16;
    CGFloat alturaChat = MAX_MENSAGENS_CHAT * alturaMensagem + 10;
    CGFloat alturaInput = 36;
    CGFloat chatY = 40; // TOPO da tela
    CGFloat p = 8;

    // ── ÁREA TRANSPARENTE para fechar teclado ──
    self.areaClique = [[UIView alloc] initWithFrame:janela.bounds];
    self.areaClique.backgroundColor = UIColor.clearColor;
    self.areaClique.userInteractionEnabled = NO; // só ativa quando chat aberto
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(fecharChat)];
    [self.areaClique addGestureRecognizer:tap];
    [janela addSubview:self.areaClique];

    // ── ÁREA DO CHAT (TOPO esquerdo) ──
    self.viewChat = [[UIView alloc] initWithFrame:CGRectMake(
        p, chatY, w * 0.65, alturaChat
    )];
    self.viewChat.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    self.viewChat.layer.cornerRadius = 6;
    self.viewChat.userInteractionEnabled = NO;
    [janela addSubview:self.viewChat];

    // Labels das mensagens — de baixo para cima
    for (int i = 0; i < MAX_MENSAGENS_CHAT; i++) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(
            6,
            alturaChat - (i+1)*alturaMensagem - 2,
            self.viewChat.bounds.size.width - 12,
            alturaMensagem
        )];
        l.font = [UIFont systemFontOfSize:11];
        l.textColor = UIColor.whiteColor;
        l.text = @"";
        l.shadowColor = [UIColor blackColor];
        l.shadowOffset = CGSizeMake(1, 1);
        [self.viewChat addSubview:l];
        [self.labelsMensagens addObject:l];
    }

    // ── INPUT DO CHAT ──
    // Aparece abaixo da área do chat quando aberto
    self.viewInput = [[UIView alloc] initWithFrame:CGRectMake(
        p, chatY + alturaChat + 4, w * 0.65, alturaInput
    )];
    self.viewInput.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    self.viewInput.layer.cornerRadius = 6;
    self.viewInput.hidden = YES;
    [janela addSubview:self.viewInput];

    // Campo de texto do chat
    self.campoChatInput = [[UITextField alloc] initWithFrame:CGRectMake(
        8, 4, self.viewInput.bounds.size.width - 60, alturaInput - 8
    )];
    self.campoChatInput.backgroundColor = UIColor.clearColor;
    self.campoChatInput.textColor = UIColor.whiteColor;
    self.campoChatInput.font = [UIFont systemFontOfSize:12];
    self.campoChatInput.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:@"Digite sua mensagem..."
        attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.5 alpha:1]}];
    self.campoChatInput.returnKeyType = UIReturnKeySend;
    self.campoChatInput.delegate = (id<UITextFieldDelegate>)self;
    [self.viewInput addSubview:self.campoChatInput];

    // Botão enviar dentro do input
    self.btnEnviar = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.btnEnviar setTitle:@"OK" forState:UIControlStateNormal];
    [self.btnEnviar setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.btnEnviar.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    self.btnEnviar.backgroundColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
    self.btnEnviar.frame = CGRectMake(
        self.viewInput.bounds.size.width - 50, 4, 42, alturaInput - 8
    );
    self.btnEnviar.layer.cornerRadius = 4;
    [self.btnEnviar addTarget:self action:@selector(enviarMensagem)
            forControlEvents:UIControlEventTouchUpInside];
    [self.viewInput addSubview:self.btnEnviar];

    // ── BOTÃO T (abrir chat) — canto SUPERIOR direito ──
    self.btnChat = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.btnChat setTitle:@"T" forState:UIControlStateNormal];
    [self.btnChat setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.btnChat.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    self.btnChat.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    self.btnChat.frame = CGRectMake(w - 44, chatY, 36, 36);
    self.btnChat.layer.cornerRadius = 6;
    [self.btnChat addTarget:self action:@selector(toggleChat)
           forControlEvents:UIControlEventTouchUpInside];
    [janela addSubview:self.btnChat];

    // Mensagens iniciais
    [self adicionarMensagem:@"SA-MP iOS iniciado!" cor:0xFFFF00FF];

    // Observar teclado
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(tecladoAbriu:)
        name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(tecladoFechou:)
        name:UIKeyboardWillHideNotification object:nil];
}

- (void)tecladoAbriu:(NSNotification*)n {
    // Não precisa mover nada pois o chat está no topo
}

- (void)tecladoFechou:(NSNotification*)n {
    // Fechar chat se teclado fechou externamente
    if (self.chatAberto) [self fecharChat];
}

- (void)toggleChat {
    if (self.chatAberto) {
        [self fecharChat];
    } else {
        [self abrirChat];
    }
}

- (void)abrirChat {
    self.chatAberto = YES;
    self.viewInput.hidden = NO;
    self.areaClique.userInteractionEnabled = YES;
    [self.btnChat setTitle:@"✕" forState:UIControlStateNormal];
    [self.campoChatInput becomeFirstResponder];
}

- (void)fecharChat {
    self.chatAberto = NO;
    self.viewInput.hidden = YES;
    self.areaClique.userInteractionEnabled = NO;
    [self.btnChat setTitle:@"T" forState:UIControlStateNormal];
    [self.campoChatInput resignFirstResponder];
    self.campoChatInput.text = @"";
}

- (void)enviarMensagem {
    NSString *texto = self.campoChatInput.text;
    if (texto.length == 0) { [self fecharChat]; return; }
    [[SAMPNetwork shared] enviarChat:texto];
    [self adicionarMensagem:[NSString stringWithFormat:@"* %@: %@",
        @"Você", texto] cor:0xFFFFFFFF];
    [self fecharChat];
}

// UITextFieldDelegate — Enter envia
- (BOOL)textFieldShouldReturn:(UITextField*)tf {
    [self enviarMensagem];
    return YES;
}

- (void)adicionarMensagem:(NSString*)texto cor:(uint32_t)cor {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mensagens insertObject:@{@"texto":texto, @"cor":@(cor)} atIndex:0];
        while (self.mensagens.count > MAX_MENSAGENS_CHAT)
            [self.mensagens removeLastObject];

        for (int i = 0; i < (int)self.labelsMensagens.count; i++) {
            UILabel *l = self.labelsMensagens[i];
            if (i < (int)self.mensagens.count) {
                NSDictionary *m = self.mensagens[i];
                l.text = m[@"texto"];
                uint32_t c = [m[@"cor"] unsignedIntValue];
                l.textColor = [UIColor
                    colorWithRed:((c>>24)&0xFF)/255.0
                           green:((c>>16)&0xFF)/255.0
                            blue:((c>>8) &0xFF)/255.0
                           alpha:( c     &0xFF)/255.0];
            } else {
                l.text = @"";
            }
        }
    });
}

- (void)parar {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.viewChat removeFromSuperview];
        [self.viewInput removeFromSuperview];
        [self.btnChat removeFromSuperview];
        [self.areaClique removeFromSuperview];
    });
}

@end
