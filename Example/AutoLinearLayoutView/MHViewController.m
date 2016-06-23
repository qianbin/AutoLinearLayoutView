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
@property (weak, nonatomic) IBOutlet UISegmentedControl *alignment;
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
    label.font = [UIFont systemFontOfSize: MAX(30.0, rand() % 100)];
    label.backgroundColor = [UIColor colorWithHue:self.foobar.subviews.count % 10 / 10.0 saturation:1 brightness:1 alpha:1];
    [label addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(subViewDidTap:)]];
    label.userInteractionEnabled = YES;
    [self.foobar addSubview:label];
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}
                                
- (void)subViewDidTap:(UIGestureRecognizer *)recognizer {
    [recognizer.view removeFromSuperview];
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

- (IBAction)axisDidChanged:(UISegmentedControl *)sender {
    if(sender.selectedSegmentIndex == 1){
        self.foobar.axisVertical = YES;
        [UIView animateWithDuration:0.5 animations:^{
            [self.view layoutIfNeeded];
        }];
        [self.alignment setTitle:@"Leading" forSegmentAtIndex:0];
        [self.alignment setTitle:@"Trailing" forSegmentAtIndex:1];
    }
    else{
        self.foobar.axisVertical = NO;
        [UIView animateWithDuration:0.5 animations:^{
            [self.view layoutIfNeeded];
        }];
        [self.alignment setTitle:@"Top" forSegmentAtIndex:0];
        [self.alignment setTitle:@"Bottom" forSegmentAtIndex:1];
    }
    [self.view layoutIfNeeded];
    [self alignmentDidChanged:self.alignment];
    
}

- (IBAction)alignmentDidChanged:(UISegmentedControl *)sender {
    self.foobar.alignTrailing = NO;
    self.foobar.alignBottom = NO;
    self.foobar.alignCenterAgainstAxis = NO;
    
    if(sender.selectedSegmentIndex == 1){
        if(self.foobar.axisVertical)
            self.foobar.alignTrailing = YES;
        else
            self.foobar.alignBottom = YES;
        self.foobar.alignBottom = YES;
    }else if(sender.selectedSegmentIndex == 2){
        self.foobar.alignCenterAgainstAxis = YES;
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
