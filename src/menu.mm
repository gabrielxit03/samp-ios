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
    
    // Fundo com gradiente escuro
    UIColor *corFundo = [UIColor colorWithRed:0.05 green:0.05 blue:0.08 alpha:1.0];
    self.view.backgroundColor = corFundo;
    
    self.servidores = [NSMutableArray arrayWithArray:@[
        @{@"nome":@"Brasil Roleplay",  @"ip":@"br-rp.com.br",  @"porta":@"7777", @"jogadores":@"100/500"},
        @{@"nome":@"Server Teste",     @"ip":@"127.0.0.1",      @"porta":@"7777", @"jogadores":@"0/100"},
    ]];
    
    // Fechar teclado ao tocar fora
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(fecharTeclado)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    
    [self configurarInterface];
    
    // Observar teclado para mover a tela
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(tecladoAbriu:)
        name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(tecladoFechou:)
        name:UIKeyboardWillHideNotification object:nil];
}

- (void)fecharTeclado {
    [self.view endEditing:YES];
}

- (void)tecladoAbriu:(NSNotification*)n {
    CGFloat altura = [n.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    [UIView animateWithDuration:0.3 animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, -altura * 0.4);
    }];
}

- (void)tecladoFechou:(NSNotification*)n {
    [UIView animateWithDuration:0.3 animations:^{
        self.view.transform = CGAffineTransformIdentity;
    }];
}

- (void)configurarInterface {
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    CGFloat p = 20;
    CGFloat y = 50;

    // ── LOGO / TÍTULO ──────────────────────────
    UILabel *titulo = [UILabel new];
    titulo.text = @"SA-MP";
    titulo.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.2 alpha:1.0];
    titulo.font = [UIFont boldSystemFontOfSize:42];
    titulo.textAlignment = NSTextAlignmentCenter;
    titulo.frame = CGRectMake(0, y, w, 50);
    [self.view addSubview:titulo]; y += 45;

    UILabel *subtitulo = [UILabel new];
    subtitulo.text = @"San Andreas Multiplayer • iOS";
    subtitulo.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    subtitulo.font = [UIFont systemFontOfSize:13];
    subtitulo.textAlignment = NSTextAlignmentCenter;
    subtitulo.frame = CGRectMake(0, y, w, 20);
    [self.view addSubview:subtitulo]; y += 35;

    // ── LINHA SEPARADORA ───────────────────────
    UIView *linha1 = [UIView new];
    linha1.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.2 alpha:0.3];
    linha1.frame = CGRectMake(p, y, w-p*2, 1);
    [self.view addSubview:linha1]; y += 20;

    // ── CAMPO NOME ─────────────────────────────
    UILabel *lNome = [UILabel new];
    lNome.text = @"APELIDO";
    lNome.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.2 alpha:1.0];
    lNome.font = [UIFont boldSystemFontOfSize:11];
    lNome.frame = CGRectMake(p, y, w-p*2, 16);
    [self.view addSubview:lNome]; y += 18;

    self.campoNome = [UITextField new];
    self.campoNome.placeholder = @"Digite seu apelido";
    self.campoNome.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:@"Digite seu apelido"
        attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.35 alpha:1]}];
    self.campoNome.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:1];
    self.campoNome.textColor = UIColor.whiteColor;
    self.campoNome.font = [UIFont systemFontOfSize:15];
    self.campoNome.frame = CGRectMake(p, y, w-p*2, 44);
    self.campoNome.layer.cornerRadius = 8;
    self.campoNome.layer.borderWidth = 1;
    self.campoNome.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:1].CGColor;
    self.campoNome.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,12,0)];
    self.campoNome.leftViewMode = UITextFieldViewModeAlways;
    self.campoNome.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:self.campoNome]; y += 52;

    // ── IP E PORTA ─────────────────────────────
    UILabel *lIP = [UILabel new];
    lIP.text = @"ENDEREÇO DO SERVIDOR";
    lIP.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.2 alpha:1.0];
    lIP.font = [UIFont boldSystemFontOfSize:11];
    lIP.frame = CGRectMake(p, y, w-p*2, 16);
    [self.view addSubview:lIP]; y += 18;

    CGFloat larguraIP = (w - p*2 - 10) * 0.72;
    CGFloat larguraPorta = (w - p*2 - 10) * 0.28;

    self.campoIP = [UITextField new];
    self.campoIP.placeholder = @"IP ou domínio";
    self.campoIP.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:@"IP ou domínio"
        attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.35 alpha:1]}];
    self.campoIP.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:1];
    self.campoIP.textColor = UIColor.whiteColor;
    self.campoIP.font = [UIFont systemFontOfSize:15];
    self.campoIP.frame = CGRectMake(p, y, larguraIP, 44);
    self.campoIP.layer.cornerRadius = 8;
    self.campoIP.layer.borderWidth = 1;
    self.campoIP.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:1].CGColor;
    self.campoIP.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,12,0)];
    self.campoIP.leftViewMode = UITextFieldViewModeAlways;
    self.campoIP.keyboardType = UIKeyboardTypeURL;
    self.campoIP.autocorrectionType = UITextAutocorrectionTypeNo;
    self.campoIP.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview:self.campoIP];

    self.campoPorta = [UITextField new];
    self.campoPorta.placeholder = @"7777";
    self.campoPorta.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:@"7777"
        attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.35 alpha:1]}];
    self.campoPorta.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:1];
    self.campoPorta.textColor = UIColor.whiteColor;
    self.campoPorta.font = [UIFont systemFontOfSize:15];
    self.campoPorta.textAlignment = NSTextAlignmentCenter;
    self.campoPorta.frame = CGRectMake(p + larguraIP + 10, y, larguraPorta, 44);
    self.campoPorta.layer.cornerRadius = 8;
    self.campoPorta.layer.borderWidth = 1;
    self.campoPorta.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:1].CGColor;
    self.campoPorta.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:self.campoPorta]; y += 52;

    // ── BOTÃO CONECTAR ─────────────────────────
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"CONECTAR" forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    btn.backgroundColor = [UIColor colorWithRed:0.0 green:0.85 blue:0.2 alpha:1.0];
    btn.frame = CGRectMake(p, y, w-p*2, 48);
    btn.layer.cornerRadius = 10;
    [btn addTarget:self action:@selector(conectar) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn]; y += 60;

    // ── LINHA SEPARADORA ───────────────────────
    UILabel *lFav = [UILabel new];
    lFav.text = @"SERVIDORES FAVORITOS";
    lFav.textColor = [UIColor colorWithWhite:0.4 alpha:1];
    lFav.font = [UIFont boldSystemFontOfSize:11];
    lFav.frame = CGRectMake(p, y, w-p*2, 16);
    [self.view addSubview:lFav]; y += 22;

    // ── LISTA DE SERVIDORES ────────────────────
    self.listaServidores = [[UITableView alloc]
        initWithFrame:CGRectMake(0, y, w, h - y)
                style:UITableViewStylePlain];
    self.listaServidores.backgroundColor = UIColor.clearColor;
    self.listaServidores.delegate = self;
    self.listaServidores.dataSource = self;
    self.listaServidores.separatorColor = [UIColor colorWithWhite:0.12 alpha:1];
    self.listaServidores.separatorInset = UIEdgeInsetsMake(0, p, 0, p);
    [self.view addSubview:self.listaServidores];
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
    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:@"SA-MP iOS"
        message:msg
        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK"
        style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)s {
    return self.servidores.count;
}

- (UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"s"];
    if (!cell) cell = [[UITableViewCell alloc]
        initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"s"];

    NSDictionary *s = self.servidores[indexPath.row];
    cell.textLabel.text = s[@"nome"];
    cell.textLabel.textColor = UIColor.whiteColor;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@:%@  •  %@ jogadores",
        s[@"ip"], s[@"porta"], s[@"jogadores"]];
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    cell.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1];

    // Ícone verde
    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0,0,8,8)];
    dot.backgroundColor = [UIColor colorWithRed:0 green:0.85 blue:0.2 alpha:1];
    dot.layer.cornerRadius = 4;
    cell.accessoryView = dot;

    return cell;
}

- (void)tableView:(UITableView*)tv didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *s = self.servidores[indexPath.row];
    self.campoIP.text = s[@"ip"];
    self.campoPorta.text = s[@"porta"];
    [tv deselectRowAtIndexPath:indexPath animated:YES];
    [self fecharTeclado];
}

- (CGFloat)tableView:(UITableView*)tv heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 62;
}

- (UIView*)tableView:(UITableView*)tv viewForHeaderInSection:(NSInteger)section {
    return nil;
}

@end
