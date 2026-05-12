#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include "samp.h"

// Esse código roda automaticamente
// quando o GTA SA iniciar
__attribute__((constructor))
static void SAMPInit() {
    NSLog(@"[SAMP-iOS] Mod carregado!");
    
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
        dispatch_get_main_queue(), ^{
        
        // Mostrar menu de servidores
        [[SAMPMenu shared] mostrar];
        NSLog(@"[SAMP-iOS] Menu iniciado!");
    });
}
