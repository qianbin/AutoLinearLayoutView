// AutoLinearLayoutView.h
//
// Copyright (c) 2016 modoohut.com
//
// cola.tin.com@gmail.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AutoLinearLayoutView.h"

static CGFloat const CONSTRAINT_PRIORITY_WEAK = 100;
static CGFloat const CONSTRAINT_PRIORITY_MEDIUM = 500;
static CGFloat const CONSTRAINT_PRIORITY_STRONG = 900;

@implementation NSLayoutConstraint (Helper)
// make a pair of Equal and GreaterThanOrEqual constraints
+ (void)_makeEqualAndGreaterConstraintsWithItem:(UIView *)view1
				      attribute:(NSLayoutAttribute)attr1
					 toItem:(UIView *)view2
				      attribute:(NSLayoutAttribute)attr2
				       constant:(CGFloat)c
				     usingBlock:(void (^)(NSLayoutConstraint *equal, NSLayoutConstraint *greater))block {
	block(
	    [NSLayoutConstraint constraintWithItem:view1 attribute:attr1 relatedBy:NSLayoutRelationEqual toItem:view2 attribute:attr2 multiplier:1 constant:c],
	    [NSLayoutConstraint constraintWithItem:view1
					 attribute:attr1
					 relatedBy:NSLayoutRelationGreaterThanOrEqual
					    toItem:view2
					 attribute:attr2
					multiplier:1
					  constant:c]);
}

// make constraints for a view to simulate intrinsic content size
+ (NSArray<NSLayoutConstraint *> *)_constraintsWithContentSize:(CGSize)size ofView:(UIView *)view {
	NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithCapacity:4];

	// for width
	[self _makeEqualAndGreaterConstraintsWithItem:view
					    attribute:NSLayoutAttributeWidth
					       toItem:nil
					    attribute:NSLayoutAttributeNotAnAttribute
					     constant:size.width
					   usingBlock:^(NSLayoutConstraint *equal, NSLayoutConstraint *greater) {

					     equal.priority = [view contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal];
					     greater.priority = [view contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisHorizontal];
					     [constraints addObject:equal];
					     [constraints addObject:greater];
					   }];

	// for height
	[self _makeEqualAndGreaterConstraintsWithItem:view
					    attribute:NSLayoutAttributeHeight
					       toItem:nil
					    attribute:NSLayoutAttributeNotAnAttribute
					     constant:size.height
					   usingBlock:^(NSLayoutConstraint *equal, NSLayoutConstraint *greater) {

					     equal.priority = [view contentHuggingPriorityForAxis:UILayoutConstraintAxisVertical];
					     greater.priority = [view contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisVertical];
					     [constraints addObject:equal];
					     [constraints addObject:greater];
					   }];

	return constraints;
}

@end

static BOOL isValidIntrinsicContentSize(CGSize size) { return !(size.width < 0 || size.height < 0); }

///////
@interface AutoLinearLayoutView () {
	NSArray<NSLayoutConstraint *> *_addedConstraints;
}
@end

IB_DESIGNABLE
@implementation AutoLinearLayoutView

#if !TARGET_INTERFACE_BUILDER
- (void)didAddSubview:(UIView *)subview {
	[super didAddSubview:subview];
	// as an auto layout fan ...
	subview.translatesAutoresizingMaskIntoConstraints = NO;
}
#endif

- (void)addConstraint:(NSLayoutConstraint *)constraint {
	// skip prototype constraints added by IB
	if ([@"NSIBPrototypingLayoutConstraint" isEqualToString:NSStringFromClass(constraint.class)])
		return;

	[super addConstraint:constraint];
}

- (void)updateConstraints {

	if (_addedConstraints) {
		[self removeConstraints:_addedConstraints];
		_addedConstraints = nil;
	}

	CGSize mySize = CGSizeZero;
	NSMutableArray<NSLayoutConstraint *> *constraintsToAdd = [NSMutableArray array];

	NSArray<UIView *> *subviews = self.subviews;
	if (subviews.count > 0) {

		CGFloat minHorizHugging = UILayoutPriorityRequired;
		CGFloat minVertHugging = UILayoutPriorityRequired;

		for (UIView *subview in subviews) {
			minHorizHugging = MIN(minHorizHugging, [subview contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal]);
			minVertHugging = MIN(minVertHugging, [subview contentHuggingPriorityForAxis:UILayoutConstraintAxisVertical]);
		}

		for (int i = 0; i < subviews.count; ++i) {
			UIView *sub = subviews[i];

			const CGFloat horizHugging = [sub contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal];
			const CGFloat vertHugging = [sub contentHuggingPriorityForAxis:UILayoutConstraintAxisVertical];

			id block = ^(NSLayoutConstraint *equal, NSLayoutConstraint *greater) {
			  [constraintsToAdd addObject:equal];
			  [constraintsToAdd addObject:greater];

			  greater.priority = CONSTRAINT_PRIORITY_STRONG;
			  equal.priority = CONSTRAINT_PRIORITY_WEAK;

			  if (equal.firstAttribute == NSLayoutAttributeLeading || equal.firstAttribute == NSLayoutAttributeTrailing) {
				  if ((_axisVertical ? horizHugging : minHorizHugging) < CONSTRAINT_PRIORITY_WEAK)
					  equal.priority = CONSTRAINT_PRIORITY_MEDIUM;
			  } else {
				  if ((_axisVertical ? minVertHugging : vertHugging) < CONSTRAINT_PRIORITY_WEAK)
					  equal.priority = CONSTRAINT_PRIORITY_MEDIUM;
			  }

			  if (equal.firstAttribute != equal.secondAttribute) {
				  // spacing
				  ++equal.priority;
				  ++greater.priority;
			  } else {
				  // insets
				  BOOL isHorizConstraint =
				      (equal.firstAttribute == NSLayoutAttributeLeading || equal.firstAttribute == NSLayoutAttributeTrailing);
				  if (_alignCenterAgainstAxis && (_axisVertical == isHorizConstraint)) {
					  //
				  } else if (equal.firstAttribute == (_alignTrailing ? NSLayoutAttributeTrailing : NSLayoutAttributeLeading) ||
					     equal.firstAttribute == (_alignBottom ? NSLayoutAttributeBottom : NSLayoutAttributeTop)) {
					  ++equal.priority;
					  ++greater.priority;
				  }
			  }
			};

			{
				// make constraints for insets against axis
				NSLayoutAttribute attribute = _axisVertical ? NSLayoutAttributeLeading : NSLayoutAttributeTop;
				[NSLayoutConstraint _makeEqualAndGreaterConstraintsWithItem:sub
										  attribute:attribute
										     toItem:self
										  attribute:attribute
										   constant:(_axisVertical ? _insets.left : _insets.top)
										 usingBlock:block];
			}
			{
				// make constraints for insets against axis
				NSLayoutAttribute attribute = _axisVertical ? NSLayoutAttributeTrailing : NSLayoutAttributeBottom;
				[NSLayoutConstraint _makeEqualAndGreaterConstraintsWithItem:self
										  attribute:attribute
										     toItem:sub
										  attribute:attribute
										   constant:(_axisVertical ? _insets.right : _insets.bottom)
										 usingBlock:block];
			}

			if (sub == subviews.firstObject) {
				// make constraints for first sub view with me
				NSLayoutAttribute attribute = _axisVertical ? NSLayoutAttributeTop : NSLayoutAttributeLeading;
				[NSLayoutConstraint _makeEqualAndGreaterConstraintsWithItem:sub
										  attribute:attribute
										     toItem:self
										  attribute:attribute
										   constant:(_axisVertical ? _insets.top : _insets.left)
										 usingBlock:block];
			} else {
				// make constraints for spacing between sub views
				[NSLayoutConstraint
				    _makeEqualAndGreaterConstraintsWithItem:sub
								  attribute:(_axisVertical ? NSLayoutAttributeTop : NSLayoutAttributeLeading)
								     toItem:subviews[i - 1]
								  attribute:(_axisVertical ? NSLayoutAttributeBottom : NSLayoutAttributeTrailing)
								   constant:_spacing
								 usingBlock:block];
			}

			if (sub == subviews.lastObject) {
				// make constraints for last sub view with me
				NSLayoutAttribute attribute = _axisVertical ? NSLayoutAttributeBottom : NSLayoutAttributeTrailing;
				[NSLayoutConstraint _makeEqualAndGreaterConstraintsWithItem:self
										  attribute:attribute
										     toItem:sub
										  attribute:attribute
										   constant:(_axisVertical ? _insets.bottom : _insets.right)
										 usingBlock:block];
			}

			if (_alignCenterAgainstAxis) {
				// make constraints for center alignment
				CGFloat constant = (_axisVertical ? (_insets.left - _insets.right) : (_insets.top - _insets.bottom)) / 2;
				NSLayoutAttribute attribute = _axisVertical ? NSLayoutAttributeCenterX : NSLayoutAttributeCenterY;
				NSLayoutConstraint *center = [NSLayoutConstraint constraintWithItem:sub
											  attribute:attribute
											  relatedBy:NSLayoutRelationEqual
											     toItem:self
											  attribute:attribute
											 multiplier:1
											   constant:constant];

				center.priority = CONSTRAINT_PRIORITY_WEAK + 1;
				[constraintsToAdd addObject:center];
			}

			if ([sub isKindOfClass:AutoLinearLayoutView.class]) {
				// important before we measure size of sub view
				[sub setNeedsUpdateConstraints];
				[sub updateConstraintsIfNeeded];
			}

			// measure
			CGSize subViewSize = [sub systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

			if (!isValidIntrinsicContentSize(sub.intrinsicContentSize) && ![sub isKindOfClass:AutoLinearLayoutView.class]) {
				// to simulate intrinsic content size for sub view that has no intrinsic content size
				[constraintsToAdd addObjectsFromArray:[NSLayoutConstraint _constraintsWithContentSize:subViewSize ofView:sub]];
			}

			mySize.width = _axisVertical ? MAX(subViewSize.width, mySize.width) : (mySize.width + MAX(subViewSize.width, 0));
			mySize.height = _axisVertical ? (mySize.height + subViewSize.height) : MAX(mySize.height, MAX(subViewSize.height, 0));
		}

		mySize.width += (_insets.left + _insets.right);
		mySize.height += (_insets.top + _insets.bottom);

		CGFloat totalSpacing = _spacing * (subviews.count - 1);
		if (_axisVertical)
			mySize.height += totalSpacing;
		else
			mySize.width += totalSpacing;
	}

	// simulate intrinsic content size to get hugging and compression work
	[constraintsToAdd addObjectsFromArray:[NSLayoutConstraint _constraintsWithContentSize:mySize ofView:self]];

	[self addConstraints:constraintsToAdd];
	_addedConstraints = constraintsToAdd;

	[super updateConstraints];
}

- (void)setAxisVertical:(BOOL)axisVertical {
	if (_axisVertical == axisVertical)
		return;

	_axisVertical = axisVertical;
#if !TARGET_INTERFACE_BUILDER
	[self setNeedsUpdateConstraints];
#endif
	[self setNeedsLayout];
}

- (void)setInsets:(UIEdgeInsets)insets {
	if (UIEdgeInsetsEqualToEdgeInsets(_insets, insets))
		return;

	_insets = insets;
#if !TARGET_INTERFACE_BUILDER
	[self setNeedsUpdateConstraints];
#endif
	[self setNeedsLayout];
}

- (void)setSpacing:(CGFloat)spacing {
	if (_spacing == spacing)
		return;

	_spacing = spacing;

#if !TARGET_INTERFACE_BUILDER
	[self setNeedsUpdateConstraints];
#endif
	[self setNeedsLayout];
}

- (void)setAlignTrailing:(BOOL)alignTrailing {
	if (_alignTrailing == alignTrailing)
		return;

	_alignTrailing = alignTrailing;

#if !TARGET_INTERFACE_BUILDER
	[self setNeedsUpdateConstraints];
#endif
	[self setNeedsLayout];
}
- (void)setAlignBottom:(BOOL)alignBottom {
	if (_alignBottom == alignBottom)
		return;

	_alignBottom = alignBottom;

#if !TARGET_INTERFACE_BUILDER
	[self setNeedsUpdateConstraints];
#endif
	[self setNeedsLayout];
}

- (void)setAlignCenterAgainstAxis:(BOOL)alignCenterAgainstAxis {
	if (_alignCenterAgainstAxis == alignCenterAgainstAxis)
		return;

	_alignCenterAgainstAxis = alignCenterAgainstAxis;

#if !TARGET_INTERFACE_BUILDER
	[self setNeedsUpdateConstraints];
#endif
	[self setNeedsLayout];
}
@end

@implementation AutoLinearLayoutView (SeparatedInsets)

- (CGFloat)insetLeading {
	return _insets.left;
}

- (void)setInsetLeading:(CGFloat)insetLeading {
	UIEdgeInsets insets = self.insets;
	insets.left = insetLeading;
	self.insets = insets;
}

- (CGFloat)insetTrailing {
	return _insets.right;
}

- (void)setInsetTrailing:(CGFloat)insetTrailing {
	UIEdgeInsets insets = self.insets;
	insets.right = insetTrailing;
	self.insets = insets;
}

- (CGFloat)insetTop {
	return _insets.top;
}

- (void)setInsetTop:(CGFloat)insetTop {
	UIEdgeInsets insets = self.insets;
	insets.top = insetTop;
	self.insets = insets;
}

- (CGFloat)insetBottom {
	return _insets.bottom;
}

- (void)setInsetBottom:(CGFloat)insetBottom {
	UIEdgeInsets insets = self.insets;
	insets.bottom = insetBottom;
	self.insets = insets;
}

@end
