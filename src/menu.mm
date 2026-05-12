#import <UIKit/UIKit.h>
#include "../include/samp.h"

@interface SAMPMenu : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITextField *campoNome;
@property (nonatomic, strong) UITextField *campoIP;
@property (nonatomic, strong) UITextField *campoPorta;
@property (nonatomic, strong) UITableView *listaServidores;
@property (nonatomic, strong) NSMutableArray *servidores;
@end

@implementation SAMPMenu

// Singleton
+ (instancetype)shared {
    static SAMPMenu *instancia = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        instancia = [[SAMPMenu alloc] init];
    });
    return instancia;
}

// Mostrar o menu
- (void)mostrar {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *vc = [UIApplication sharedApplication]
            .keyWindow.rootViewController;
        
        UINavigationController *nav = [[UINavigationController alloc]
            initWithRootViewController:self];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [vc presentViewController:nav animated:YES completion:nil];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Fundo escuro igual ao SA-MP
    self.view.backgroundColor = [UIColor colorWithRed:0.1 
                                                green:0.1 
                                                 blue:0.1 
                                                alpha:1.0];
    self.title = @"SA-MP iOS";
    
    // Lista de servidores favoritos
    self.servidores = [NSMutableArray arrayWithArray:@[
        @{@"nome": @"Brasil Roleplay", 
          @"ip": @"192.168.1.1", 
          @"porta": @"7777",
          @"jogadores": @"100/500"},
        @{@"nome": @"Servidor Teste", 
          @"ip": @"127.0.0.1", 
          @"porta": @"7777",
          @"jogadores": @"0/100"},
    ]];
    
    [self configurarInterface];
}

- (void)configurarInterface {
    CGFloat largura = self.view.bounds.size.width;
    CGFloat y = 20;
    CGFloat padding = 15;
    
    // Label nome
    UILabel *labelNome = [UILabel new];
    labelNome.text = @"Seu nome:";
    labelNome.textColor = [UIColor whiteColor];
    labelNome.frame = CGRectMake(padding, y, largura - padding*2, 25);
    [self.view addSubview:labelNome];
    y += 30;
    
    // Campo nome
    self.campoNome = [UITextField new];
    self.campoNome.placeholder = @"Digite seu nome...";
    self.campoNome.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    self.campoNome.textColor = [UIColor whiteColor];
    self.campoNome.frame = CGRectMake(padding, y, largura - padding*2, 40);
    self.campoNome.layer.cornerRadius = 5;
    self.campoNome.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,10,0)];
    self.campoNome.leftViewMode = UITextFieldViewModeAlways;
    [self.view addSubview:self.campoNome];
    y += 50;
    
    // Label IP
    UILabel *labelIP = [UILabel new];
    labelIP.text = @"IP do servidor:";
    labelIP.textColor = [UIColor whiteColor];
    labelIP.frame = CGRectMake(padding, y, largura - padding*2, 25);
    [self.view addSubview:labelIP];
    y += 30;
    
    // Campo IP e Porta na mesma linha
    self.campoIP = [UITextField new];
    self.campoIP.placeholder = @"IP ex: 127.0.0.1";
    self.campoIP.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    self.campoIP.textColor = [UIColor whiteColor];
    self.campoIP.frame = CGRectMake(padding, y, (largura - padding*3) * 0.7, 40);
    self.campoIP.layer.cornerRadius = 5;
    self.campoIP.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,10,0)];
    self.campoIP.leftViewMode = UITextFieldViewModeAlways;
    self.campoIP.keyboardType = UIKeyboardTypeDecimalPad;
    [self.view addSubview:self.campoIP];
    
    self.campoPorta = [UITextField new];
    self.campoPorta.placeholder = @"7777";
    self.campoPorta.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    self.campoPorta.textColor = [UIColor whiteColor];
    self.campoPorta.frame = CGRectMake(
        padding + (largura - padding*3) * 0.7 + padding, 
        y, 
        (largura - padding*3) * 0.3, 
        40
    );
    self.campoPorta.layer.cornerRadius = 5;
    self.campoPorta.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,10,0)];
    self.campoPorta.leftViewMode = UITextFieldViewModeAlways;
    self.campoPorta.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:self.campoPorta];
    y += 50;
    
    // Botão conectar
    UIButton *btnConectar = [UIButton buttonWithType:UIButtonTypeSystem];
    [btnConectar setTitle:@"CONECTAR" forState:UIControlStateNormal];
    [btnConectar setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnConectar.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    btnConectar.backgroundColor = [UIColor colorWithRed:0.0 
                                                   green:0.6 
                                                    blue:0.0 
                                                   alpha:1.0];
    btnConectar.frame = CGRectMake(padding, y, largura - padding*2, 45);
    btnConectar.layer.cornerRadius = 8;
    [btnConectar addTarget:self 
                    action:@selector(conectar) 
          forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnConectar];
    y += 60;
    
    // Label servidores favoritos
    UILabel *labelFav = [UILabel new];
    labelFav.text = @"Servidores favoritos:";
    labelFav.textColor = [UIColor grayColor];
    labelFav.frame = CGRectMake(padding, y, largura - padding*2, 25);
    [self.view addSubview:labelFav];
    y += 30;
    
    // Lista de servidores
    self.listaServidores = [[UITableView alloc] 
        initWithFrame:CGRectMake(0, y, largura, 
                                 self.view.bounds.size.height - y)
                style:UITableViewStylePlain];
    self.listaServidores.backgroundColor = [UIColor clearColor];
    self.listaServidores.delegate = self;
    self.listaServidores.dataSource = self;
    self.listaServidores.separatorColor = [UIColor colorWithWhite:0.3 alpha:1];
    [self.view addSubview:self.listaServidores];
}

// Conectar ao servidor
- (void)conectar {
    NSString *nome = self.campoNome.text;
    NSString *ip = self.campoIP.text;
    NSString *portaStr = self.campoPorta.text;
    
    // Validações básicas
    if (nome.length == 0) {
        [self mostrarAlerta:@"Digite seu nome!"];
        return;
    }
    if (ip.length == 0) {
        [self mostrarAlerta:@"Digite o IP do servidor!"];
        return;
    }
    
    int porta = portaStr.length > 0 ? portaStr.intValue : SAMP_PORT;
    
    NSLog(@"[SAMP-iOS] Conectando em %@:%d como %@", ip, porta, nome);
    
    // Iniciar conexão
    [[SAMPNetwork shared] conectar:ip porta:porta nome:nome];
    
    // Fechar menu
    [self dismissViewControllerAnimated:YES completion:^{
        // Iniciar HUD
        [[SAMPHUD shared] iniciar];
    }];
}

- (void)mostrarAlerta:(NSString*)mensagem {
    UIAlertController *alert = [UIAlertController 
        alertControllerWithTitle:@"SAMP iOS"
        message:mensagem
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" 
                                             style:UIAlertActionStyleDefault 
                                           handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

// TableView - quantidade de linhas
- (NSInteger)tableView:(UITableView*)tableView 
 numberOfRowsInSection:(NSInteger)section {
    return self.servidores.count;
}

// TableView - cada célula
- (UITableViewCell*)tableView:(UITableView*)tableView 
        cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    UITableViewCell *cell = [tableView 
        dequeueReusableCellWithIdentifier:@"servidor"];
    if (!cell) {
        cell = [[UITableViewCell alloc] 
            initWithStyle:UITableViewCellStyleSubtitle 
            reuseIdentifier:@"servidor"];
    }
    
    NSDictionary *servidor = self.servidores[indexPath.row];
    cell.textLabel.text = servidor[@"nome"];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@:%@ | %@ jogadores",
        servidor[@"ip"], servidor[@"porta"], servidor[@"jogadores"]];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
    
    return cell;
}

// TableView - ao tocar em um servidor
- (void)tableView:(UITableView*)tableView 
didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    
    NSDictionary *servidor = self.servidores[indexPath.row];
    self.campoIP.text = servidor[@"ip"];
    self.campoPorta.text = servidor[@"porta"];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView*)tableView 
heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 60;
}

@end
