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
        [janela.rootViewController presentViewController:nav animated:YES completion:nil];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
    self.title = @"SA-MP iOS";
    self.servidores = [NSMutableArray arrayWithArray:@[
        @{@"nome":@"Brasil Roleplay", @"ip":@"192.168.1.1", @"porta":@"7777", @"jogadores":@"100/500"},
        @{@"nome":@"Servidor Teste",  @"ip":@"127.0.0.1",   @"porta":@"7777", @"jogadores":@"0/100"},
    ]];
    [self configurarInterface];
}

- (void)configurarInterface {
    CGFloat w = self.view.bounds.size.width;
    CGFloat y = 20, p = 15;

    // Label nome
    UILabel *lNome = [UILabel new];
    lNome.text = @"Seu nome:";
    lNome.textColor = UIColor.whiteColor;
    lNome.frame = CGRectMake(p, y, w-p*2, 25);
    [self.view addSubview:lNome]; y += 30;

    // Campo nome
    self.campoNome = [UITextField new];
    self.campoNome.placeholder = @"Digite seu nome...";
    self.campoNome.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    self.campoNome.textColor = UIColor.whiteColor;
    self.campoNome.frame = CGRectMake(p, y, w-p*2, 40);
    self.campoNome.layer.cornerRadius = 5;
    self.campoNome.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,10,0)];
    self.campoNome.leftViewMode = UITextFieldViewModeAlways;
    [self.view addSubview:self.campoNome]; y += 50;

    // Label IP
    UILabel *lIP = [UILabel new];
    lIP.text = @"IP do servidor:";
    lIP.textColor = UIColor.whiteColor;
    lIP.frame = CGRectMake(p, y, w-p*2, 25);
    [self.view addSubview:lIP]; y += 30;

    // Campo IP
    self.campoIP = [UITextField new];
    self.campoIP.placeholder = @"ex: 127.0.0.1";
    self.campoIP.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    self.campoIP.textColor = UIColor.whiteColor;
    self.campoIP.frame = CGRectMake(p, y, (w-p*3)*0.7, 40);
    self.campoIP.layer.cornerRadius = 5;
    self.campoIP.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,10,0)];
    self.campoIP.leftViewMode = UITextFieldViewModeAlways;
    self.campoIP.keyboardType = UIKeyboardTypeDecimalPad;
    [self.view addSubview:self.campoIP];

    // Campo Porta
    self.campoPorta = [UITextField new];
    self.campoPorta.placeholder = @"7777";
    self.campoPorta.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    self.campoPorta.textColor = UIColor.whiteColor;
    self.campoPorta.frame = CGRectMake(p+(w-p*3)*0.7+p, y, (w-p*3)*0.3, 40);
    self.campoPorta.layer.cornerRadius = 5;
    self.campoPorta.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,10,0)];
    self.campoPorta.leftViewMode = UITextFieldViewModeAlways;
    self.campoPorta.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:self.campoPorta]; y += 50;

    // Botão conectar
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"CONECTAR" forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    btn.backgroundColor = [UIColor colorWithRed:0 green:0.6 blue:0 alpha:1];
    btn.frame = CGRectMake(p, y, w-p*2, 45);
    btn.layer.cornerRadius = 8;
    [btn addTarget:self action:@selector(conectar) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn]; y += 60;

    // Label favoritos
    UILabel *lFav = [UILabel new];
    lFav.text = @"Servidores favoritos:";
    lFav.textColor = UIColor.grayColor;
    lFav.frame = CGRectMake(p, y, w-p*2, 25);
    [self.view addSubview:lFav]; y += 30;

    // Lista servidores
    self.listaServidores = [[UITableView alloc]
        initWithFrame:CGRectMake(0, y, w, self.view.bounds.size.height-y)
                style:UITableViewStylePlain];
    self.listaServidores.backgroundColor = UIColor.clearColor;
    self.listaServidores.delegate = self;
    self.listaServidores.dataSource = self;
    self.listaServidores.separatorColor = [UIColor colorWithWhite:0.3 alpha:1];
    [self.view addSubview:self.listaServidores];
}

- (void)conectar {
    NSString *nome = self.campoNome.text;
    NSString *ip   = self.campoIP.text;
    NSString *portaStr = self.campoPorta.text;
    if (nome.length == 0) { [self alerta:@"Digite seu nome!"]; return; }
    if (ip.length == 0)   { [self alerta:@"Digite o IP!"]; return; }
    int porta = portaStr.length > 0 ? portaStr.intValue : SAMP_PORT;
    [[SAMPNetwork shared] conectar:ip porta:porta nome:nome];
    [self dismissViewControllerAnimated:YES completion:^{
        [[SAMPHUD shared] iniciar];
    }];
}

- (void)alerta:(NSString*)msg {
    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:@"SAMP iOS"
        message:msg
        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK"
                                         style:UIAlertActionStyleDefault
                                       handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)s {
    return self.servidores.count;
}

- (UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"s"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"s"];
    NSDictionary *s = self.servidores[indexPath.row];
    cell.textLabel.text = s[@"nome"];
    cell.textLabel.textColor = UIColor.whiteColor;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@:%@ | %@ jogadores",
        s[@"ip"], s[@"porta"], s[@"jogadores"]];
    cell.detailTextLabel.textColor = UIColor.grayColor;
    cell.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
    return cell;
}

- (void)tableView:(UITableView*)tv didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *s = self.servidores[indexPath.row];
    self.campoIP.text = s[@"ip"];
    self.campoPorta.text = s[@"porta"];
    [tv deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView*)tv heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 60;
}

@end
