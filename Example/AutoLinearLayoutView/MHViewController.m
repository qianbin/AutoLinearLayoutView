//
//  MHViewController.m
//  AutoLinearLayoutView
//
//  Created by 钱斌 on 04/06/2016.
//  Copyright (c) 2016 钱斌. All rights reserved.
//

#import "MHViewController.h"

@interface MHViewController ()
@property (weak, nonatomic) IBOutlet AutoLinearLayoutView *foobar;
@end

@implementation MHViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    srand((int)time(NULL));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addSubView:(UIButton*)sender {
    static NSString * const text = @"AutoLinearLayoutView";
    const NSUInteger subviewCount = self.foobar.subviews.count;
    CGPoint point = [sender convertPoint:CGPointMake(sender.bounds.size.width/2, sender.bounds.size.height/2) toView:self.foobar];
    UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(point.x, point.y, 0, 0)];
    label.text = [text substringWithRange:NSMakeRange(subviewCount% text.length, 1)];
    label.font = [UIFont systemFontOfSize: MAX(14.0, rand() % 100)];
    label.backgroundColor = [UIColor colorWithHue:self.foobar.subviews.count % 7 / 7.0 saturation:1 brightness:1 alpha:1];
    [self.foobar addSubview:label];
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)clearSubView:(id)sender {
    for(UIView * sub in self.foobar.subviews){
        [sub removeFromSuperview];
    }
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];

}

- (IBAction)toggleAxis:(id)sender {
    self.foobar.axisVertical = !self.foobar.axisVertical;
    
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
}
- (IBAction)toggleAlignment:(id)sender {
    self.foobar.alignCenterAgainstAxis = !self.foobar.alignCenterAgainstAxis;
    if(self.foobar.axisVertical){
        if(!self.foobar.alignCenterAgainstAxis)
            self.foobar.alignTrailing = !self.foobar.alignTrailing;
        
    }else{
        if(!self.foobar.alignCenterAgainstAxis)
            self.foobar.alignBottom = !self.foobar.alignBottom;
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)insetsDidChanged:(UIStepper *)sender {
    CGFloat value = sender.value;
    self.foobar.insets = UIEdgeInsetsMake(value, value, value, value);
    
    
}
- (IBAction)spacingDidChanged:(UIStepper*)sender {
    self.foobar.spacing = sender.value;
    
    
}
- (IBAction)textDidChanged:(UITextField*)sender {
    
    [sender invalidateIntrinsicContentSize];
    
}
- (IBAction)textEditDidEnd:(UITextField *)sender {
    [sender invalidateIntrinsicContentSize];
}


- (IBAction)toggleHuggingPriority:(UIButton *)sender {
    if([sender contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal] < 100){
        [sender setContentHuggingPriority:250 forAxis:UILayoutConstraintAxisHorizontal];
        
    }
    else{
        [sender setContentHuggingPriority:50 forAxis:UILayoutConstraintAxisHorizontal];
        
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
}


@end
