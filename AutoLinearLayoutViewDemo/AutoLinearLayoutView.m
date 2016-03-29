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

static CGFloat const PRIORITY_BASE = 100;

@implementation UIView (ConstraintsHelper)

// build width and height constraints to simulate intrinsic content size
- (void)buildConstraintsForContentSize:(CGSize)size addTo:(NSMutableArray<NSLayoutConstraint *> *)constraintsArray {

	NSLayoutConstraint *cons = [NSLayoutConstraint constraintWithItem:self
								attribute:NSLayoutAttributeWidth
								relatedBy:NSLayoutRelationEqual
								   toItem:nil
								attribute:NSLayoutAttributeNotAnAttribute
							       multiplier:1
								 constant:size.width];
	cons.priority = [self contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal];
	[constraintsArray addObject:cons];

	cons = [NSLayoutConstraint constraintWithItem:self
					    attribute:NSLayoutAttributeWidth
					    relatedBy:NSLayoutRelationGreaterThanOrEqual
					       toItem:nil
					    attribute:NSLayoutAttributeNotAnAttribute
					   multiplier:1
					     constant:size.width];
	cons.priority = [self contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisHorizontal];
	[constraintsArray addObject:cons];

	cons = [NSLayoutConstraint constraintWithItem:self
					    attribute:NSLayoutAttributeHeight
					    relatedBy:NSLayoutRelationEqual
					       toItem:nil
					    attribute:NSLayoutAttributeNotAnAttribute
					   multiplier:1
					     constant:size.height];
	cons.priority = [self contentHuggingPriorityForAxis:UILayoutConstraintAxisVertical];
	[constraintsArray addObject:cons];

	cons = [NSLayoutConstraint constraintWithItem:self
					    attribute:NSLayoutAttributeHeight
					    relatedBy:NSLayoutRelationGreaterThanOrEqual
					       toItem:nil
					    attribute:NSLayoutAttributeNotAnAttribute
					   multiplier:1
					     constant:size.height];
	cons.priority = [self contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisVertical];
	[constraintsArray addObject:cons];
}

- (void)buildConstraintsForAttribute:(NSLayoutAttribute)attr
		     relatedWithItem:(UIView *)other
			   attribute:(NSLayoutAttribute)otherAttr
			    constant:(CGFloat)c
			priorityPlus:(CGFloat)pplus
			       addTo:(NSMutableArray<NSLayoutConstraint *> *)constraintsArray {

	NSLayoutConstraint *cons = [NSLayoutConstraint constraintWithItem:self
								attribute:attr
								relatedBy:NSLayoutRelationEqual
								   toItem:other
								attribute:otherAttr
							       multiplier:1
								 constant:c];
	cons.priority = PRIORITY_BASE + pplus;
	[constraintsArray addObject:cons];

	cons = [NSLayoutConstraint constraintWithItem:self
					    attribute:attr
					    relatedBy:NSLayoutRelationGreaterThanOrEqual
					       toItem:other
					    attribute:otherAttr
					   multiplier:1
					     constant:c];
	cons.priority = (UILayoutPriorityRequired - PRIORITY_BASE) + pplus;
	[constraintsArray addObject:cons];
}
@end

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

- (void)addConstraint:(NSLayoutConstraint *)constraint {
	// skip prototype constraints added by IB
	if ([@"NSIBPrototypingLayoutConstraint" isEqualToString:NSStringFromClass(constraint.class)])
		return;

	[super addConstraint:constraint];
}
#endif

- (NSInteger)nestingDepth {
	NSInteger depth = 0;
	UIView *view = self.superview;
	while (view) {
		if ([view isKindOfClass:AutoLinearLayoutView.class])
			++depth;
		view = view.superview;
	}
	return depth;
}

- (void)updateConstraints {

	if (_addedConstraints) {
		[self removeConstraints:_addedConstraints];
		_addedConstraints = nil;
	}

	// priority of constraints should be decreased for nested view
	// double it to make center alignment work
	const CGFloat priorityMinus = [self nestingDepth] * 2;

	CGSize mySize = CGSizeZero;

	NSArray<UIView *> *subviews = self.subviews;
	if (subviews.count > 0) {

		NSMutableArray<NSLayoutConstraint *> *consToAdd = [NSMutableArray array];

		for (int i = 0; i < subviews.count; ++i) {
			UIView *sub = subviews[i];

			CGSize subViewSize = sub.intrinsicContentSize;
			if (subViewSize.width < 0 || subViewSize.height < 0) {
				// has no intrinsic content size
				if ([sub isKindOfClass:AutoLinearLayoutView.class]) {
					// important for nested view
					[sub setNeedsUpdateConstraints];
					[sub updateConstraintsIfNeeded];
				}
				// measure
				subViewSize = [sub systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

				if (![sub isKindOfClass:AutoLinearLayoutView.class]) {
					// AutoLinearLayoutView will add size constraints itself
					if (subViewSize.width >= 0 && subViewSize.height >= 0) {
						[sub buildConstraintsForContentSize:subViewSize addTo:consToAdd];
					}
				}
			}

			if (_axisVertical) {
				if (subViewSize.width > 0)
					mySize.width = MAX(subViewSize.width, mySize.width);

				if (subViewSize.height > 0)
					mySize.height += subViewSize.height;

				if (i > 0) {
					mySize.height += _spacing;
					// spacing
					[sub buildConstraintsForAttribute:NSLayoutAttributeTop
							  relatedWithItem:subviews[i - 1]
								attribute:NSLayoutAttributeBottom
								 constant:_spacing
							     priorityPlus:2 - priorityMinus
								    addTo:consToAdd];
				}

				if (i == 0) {
					// top inset
					[sub buildConstraintsForAttribute:NSLayoutAttributeTop
							  relatedWithItem:self
								attribute:NSLayoutAttributeTop
								 constant:_insets.top
							     priorityPlus:(_alignBottom ? 0 : 1) - priorityMinus
								    addTo:consToAdd];
				}
				if (i == subviews.count - 1) {
					// bottom inset
					[self buildConstraintsForAttribute:NSLayoutAttributeBottom
							   relatedWithItem:sub
								 attribute:NSLayoutAttributeBottom
								  constant:_insets.bottom
							      priorityPlus:(_alignBottom ? 1 : 0) - priorityMinus
								     addTo:consToAdd];
				}

				// leading inset
				[sub buildConstraintsForAttribute:NSLayoutAttributeLeading
						  relatedWithItem:self
							attribute:NSLayoutAttributeLeading
							 constant:_insets.left
						     priorityPlus:(_alignTrailing ? 0 : 1) - priorityMinus
							    addTo:consToAdd];

				// trailing inset
				[self buildConstraintsForAttribute:NSLayoutAttributeTrailing
						   relatedWithItem:sub
							 attribute:NSLayoutAttributeTrailing
							  constant:_insets.right
						      priorityPlus:(_alignTrailing ? 1 : 0) - priorityMinus
							     addTo:consToAdd];

			} else {
				if (subViewSize.width > 0)
					mySize.width += subViewSize.width;

				if (subViewSize.height > 0)
					mySize.height = MAX(mySize.height, subViewSize.height);

				if (i > 0) {
					mySize.width += _spacing;
					// spacing
					[sub buildConstraintsForAttribute:NSLayoutAttributeLeading
							  relatedWithItem:subviews[i - 1]
								attribute:NSLayoutAttributeTrailing
								 constant:_spacing
							     priorityPlus:2 - priorityMinus
								    addTo:consToAdd];
				}

				if (i == 0) {
					// leading inset
					[sub buildConstraintsForAttribute:NSLayoutAttributeLeading
							  relatedWithItem:self
								attribute:NSLayoutAttributeLeading
								 constant:_insets.left
							     priorityPlus:(_alignTrailing ? 0 : 1) - priorityMinus
								    addTo:consToAdd];
				}

				if (i == subviews.count - 1) {
					// trailing inset
					[self buildConstraintsForAttribute:NSLayoutAttributeTrailing
							   relatedWithItem:sub
								 attribute:NSLayoutAttributeTrailing
								  constant:_insets.right
							      priorityPlus:(_alignTrailing ? 1 : 0) - priorityMinus
								     addTo:consToAdd];
				}

				// top inset
				[sub buildConstraintsForAttribute:NSLayoutAttributeTop
						  relatedWithItem:self
							attribute:NSLayoutAttributeTop
							 constant:_insets.top
						     priorityPlus:(_alignBottom ? 0 : 1) - priorityMinus
							    addTo:consToAdd];

				// bottom inset
				[self buildConstraintsForAttribute:NSLayoutAttributeBottom
						   relatedWithItem:sub
							 attribute:NSLayoutAttributeBottom
							  constant:_insets.bottom
						      priorityPlus:(_alignBottom ? 1 : 0) - priorityMinus
							     addTo:consToAdd];
			}
		}

		mySize.width += (_insets.left + _insets.right);
		mySize.height += (_insets.top + _insets.bottom);

		// simulate intrinsic content size to get hugging and compression work
		[self buildConstraintsForContentSize:mySize addTo:consToAdd];

		[self addConstraints:consToAdd];
		_addedConstraints = consToAdd;
	}

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

@end
