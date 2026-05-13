#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include "samp.h"

// Tenta clicar em "Skip This" automaticamente
static void tentarPularSocialClub() {
    UIWindow *janela = getJanela();
    if (!janela) return;

    // Procurar botão Skip recursivamente
    for (UIView *v in janela.subviews) {
        for (UIView *sub in v.subviews) {
            if ([sub isKindOfClass:[UIButton class]]) {
                UIButton *btn = (UIButton*)sub;
                NSString *titulo = [btn titleForState:UIControlStateNormal];
                if ([titulo containsString:@"SKIP"] || [titulo containsString:@"Skip"]) {
                    NSLog(@"[SAMP] Pulando Social Club...");
                    [btn sendActionsForControlEvents:UIControlEventTouchUpInside];
                    return;
                }
            }
        }
    }
}

__attribute__((constructor))
static void SAMPInit() {
    NSLog(@"[SAMP-iOS] Mod carregado!");

    // Tentar pular Social Club após 1 segundo
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
        dispatch_get_main_queue(), ^{
        tentarPularSocialClub();
    });

    // Mostrar menu SAMP após 2 segundos
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
        dispatch_get_main_queue(), ^{
        [[SAMPMenu shared] mostrar];
        NSLog(@"[SAMP-iOS] Menu iniciado!");
    });
}
