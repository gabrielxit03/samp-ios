#import <UIKit/UIKit.h>
#include "../include/samp.h"

@implementation SAMPMenu

+ (instancetype)shared {
    static SAMPMenu *i = nil;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ i = [[SAMPMenu alloc] init]; });
    return i;
}

- (void)mostrar {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *janela = getJanela();
        UINavigationController *nav = [[UINavigationController alloc]
            initWithRootViewController:self];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        nav.navigationBar.hidden = YES;
        [janela.rootViewController presentViewController:nav animated:YES completion:nil];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.08 alpha:1.0];
    self.servidores = [NSMutableArray arrayWithArray:@[
        @{@"nome":@"Brasil RP Phoenix",  @"ip":@"brp2.phoenixhost.com.br", @"porta":@"7777", @"jogadores":@"0/500"},
        @{@"nome":@"Brasil RP",          @"ip":@"brp.phoenixhost.com.br",  @"porta":@"7777", @"jogadores":@"0/500"},
        @{@"nome":@"Servidor Teste",     @"ip":@"127.0.0.1",               @"porta":@"7777", @"jogadores":@"0/100"},
    ]];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(fecharTeclado)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(tecladoAbriu:)
        name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(tecladoFechou:)
        name:UIKeyboardWillHideNotification object:nil];

    [self configurarInterface];
}

- (void)fecharTeclado { [self.view endEditing:YES]; }

- (void)tecladoAbriu:(NSNotification*)n {
    CGFloat h = [n.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    [UIView animateWithDuration:0.3 animations:^{ self.view.transform = CGAffineTransformMakeTranslation(0, -h*0.4); }];
}

- (void)tecladoFechou:(NSNotification*)n {
    [UIView animateWithDuration:0.3 animations:^{ self.view.transform = CGAffineTransformIdentity; }];
}

- (void)configurarInterface {
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    CGFloat p = 20, y = 50;

    // Título
    UILabel *titulo = [UILabel new];
    titulo.text = @"SA-MP";
    titulo.textColor = [UIColor colorWithRed:0.0 green:0.85 blue:0.2 alpha:1.0];
    titulo.font = [UIFont boldSystemFontOfSize:42];
    titulo.textAlignment = NSTextAlignmentCenter;
    titulo.frame = CGRectMake(0, y, w, 50);
    [self.view addSubview:titulo]; y += 45;

    UILabel *sub = [UILabel new];
    sub.text = @"San Andreas Multiplayer • iOS";
    sub.textColor = [UIColor colorWithWhite:0.4 alpha:1];
    sub.font = [UIFont systemFontOfSize:13];
    sub.textAlignment = NSTextAlignmentCenter;
    sub.frame = CGRectMake(0, y, w, 20);
    [self.view addSubview:sub]; y += 35;

    UIView *linha = [UIView new];
    linha.backgroundColor = [UIColor colorWithRed:0.0 green:0.85 blue:0.2 alpha:0.3];
    linha.frame = CGRectMake(p, y, w-p*2, 1);
    [self.view addSubview:linha]; y += 20;

    // Campo apelido
    [self addLabel:@"APELIDO" y:y w:w p:p];  y += 18;
    self.campoNome = [self criarCampo:@"Digite seu apelido" y:y w:w p:p keyboard:UIKeyboardTypeDefault];
    [self.view addSubview:self.campoNome]; y += 52;

    // Campos IP e Porta
    [self addLabel:@"ENDEREÇO DO SERVIDOR" y:y w:w p:p]; y += 18;
    CGFloat larguraIP = (w-p*2-10)*0.72;
    CGFloat larguraPorta = (w-p*2-10)*0.28;

    self.campoIP = [[UITextField alloc] initWithFrame:CGRectMake(p, y, larguraIP, 44)];
    [self estilizarCampo:self.campoIP placeholder:@"IP ou domínio" keyboard:UIKeyboardTypeURL];
    self.campoIP.autocorrectionType = UITextAutocorrectionTypeNo;
    self.campoIP.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview:self.campoIP];

    self.campoPorta = [[UITextField alloc] initWithFrame:CGRectMake(p+larguraIP+10, y, larguraPorta, 44)];
    [self estilizarCampo:self.campoPorta placeholder:@"7777" keyboard:UIKeyboardTypeNumberPad];
    self.campoPorta.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.campoPorta]; y += 52;

    // Botão conectar
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"CONECTAR" forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    btn.backgroundColor = [UIColor colorWithRed:0.0 green:0.85 blue:0.2 alpha:1.0];
    btn.frame = CGRectMake(p, y, w-p*2, 48);
    btn.layer.cornerRadius = 10;
    [btn addTarget:self action:@selector(conectar) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn]; y += 60;

    // Label servidores favoritos
    UILabel *lFav = [UILabel new];
    lFav.text = @"SERVIDORES FAVORITOS";
    lFav.textColor = [UIColor colorWithWhite:0.4 alpha:1];
    lFav.font = [UIFont boldSystemFontOfSize:11];
    lFav.frame = CGRectMake(p, y, w-p*2, 16);
    [self.view addSubview:lFav]; y += 22;

    // Lista de servidores
    self.listaServidores = [[UITableView alloc]
        initWithFrame:CGRectMake(0, y, w, h-y)
                style:UITableViewStylePlain];
    self.listaServidores.backgroundColor = UIColor.clearColor;
    self.listaServidores.delegate = self;
    self.listaServidores.dataSource = self;
    self.listaServidores.separatorColor = [UIColor colorWithWhite:0.12 alpha:1];
    [self.view addSubview:self.listaServidores];
}

- (void)addLabel:(NSString*)texto y:(CGFloat)y w:(CGFloat)w p:(CGFloat)p {
    UILabel *l = [UILabel new];
    l.text = texto;
    l.textColor = [UIColor colorWithRed:0.0 green:0.85 blue:0.2 alpha:1.0];
    l.font = [UIFont boldSystemFontOfSize:11];
    l.frame = CGRectMake(p, y, w-p*2, 16);
    [self.view addSubview:l];
}

- (UITextField*)criarCampo:(NSString*)ph y:(CGFloat)y w:(CGFloat)w p:(CGFloat)p keyboard:(UIKeyboardType)kb {
    UITextField *f = [[UITextField alloc] initWithFrame:CGRectMake(p, y, w-p*2, 44)];
    [self estilizarCampo:f placeholder:ph keyboard:kb];
    return f;
}

- (void)estilizarCampo:(UITextField*)f placeholder:(NSString*)ph keyboard:(UIKeyboardType)kb {
    f.attributedPlaceholder = [[NSAttributedString alloc] initWithString:ph
        attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.35 alpha:1]}];
    f.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:1];
    f.textColor = UIColor.whiteColor;
    f.font = [UIFont systemFontOfSize:15];
    f.layer.cornerRadius = 8;
    f.layer.borderWidth = 1;
    f.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:1].CGColor;
    f.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,12,0)];
    f.leftViewMode = UITextFieldViewModeAlways;
    f.keyboardType = kb;
    f.returnKeyType = UIReturnKeyDone;
}

- (void)conectar {
    [self fecharTeclado];
    NSString *nome = self.campoNome.text;
    NSString *ip   = self.campoIP.text;
    NSString *portaStr = self.campoPorta.text;
    if (nome.length == 0) { [self alerta:@"Digite seu apelido!"]; return; }
    if (ip.length == 0)   { [self alerta:@"Digite o IP do servidor!"]; return; }
    int porta = portaStr.length > 0 ? portaStr.intValue : SAMP_PORT;
    [[SAMPNetwork shared] conectar:ip porta:porta nome:nome];
    [self dismissViewControllerAnimated:YES completion:^{
        [[SAMPHUD shared] iniciar];
    }];
}

- (void)alerta:(NSString*)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"SA-MP iOS"
        message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)s {
    return self.servidores.count;
}

- (UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)ip {
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"s"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"s"];
    NSDictionary *s = self.servidores[ip.row];
    cell.textLabel.text = s[@"nome"];
    cell.textLabel.textColor = UIColor.whiteColor;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@:%@  •  %@ jogadores", s[@"ip"], s[@"porta"], s[@"jogadores"]];
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    cell.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1];
    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0,0,8,8)];
    dot.backgroundColor = [UIColor colorWithRed:0 green:0.85 blue:0.2 alpha:1];
    dot.layer.cornerRadius = 4;
    cell.accessoryView = dot;
    return cell;
}

- (void)tableView:(UITableView*)tv didSelectRowAtIndexPath:(NSIndexPath*)ip {
    NSDictionary *s = self.servidores[ip.row];
    self.campoIP.text = s[@"ip"];
    self.campoPorta.text = s[@"porta"];
    [tv deselectRowAtIndexPath:ip animated:YES];
    [self fecharTeclado];
}

- (CGFloat)tableView:(UITableView*)tv heightForRowAtIndexPath:(NSIndexPath*)ip { return 62; }

@end
