//
//  DetailViewController.h
//  BackgroundInsertionTest
//
//  Created by Daniel Tull on 15.12.2011.
//  Copyright (c) 2011 Daniel Tull Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
