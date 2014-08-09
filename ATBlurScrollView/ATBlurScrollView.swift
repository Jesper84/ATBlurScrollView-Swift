//
//  ATBlurScrollView.swift
//
//  Created by Jesper Nielsen on 07/08/14.
//  Copyright (c) 2014 Anders Holm. All rights reserved.
//

import UIKit
import QuartzCore

var BLUR_RADIUS: CGFloat = 14
var BLUR_TINT_COLOR = UIColor(white: 0, alpha: 0.3)
var BLUR_DELTA_FACTOR: CGFloat = 1.4
var MAX_BACKGROUND_MOVEMENT_VERTICAL: CGFloat = 30
var MAX_BACKGROUND_MOVEMENT_HORIZONTAL: CGFloat = 0

var TOP_FADING_HEIGHT_HALF: CGFloat = 10

@objc protocol ATBlurScrollViewDelegate
{
    optional func blurScrollView(blurScrollView:ATBlurScrollView, didChangedToFrame:CGRect)
}

class ATBlurScrollView: UIView, UIScrollViewDelegate {
    var _backgroundImage:UIImage!
    var _blurredBackgroundImage: UIImage!
    var _viewDistanceFromBottom: CGFloat!
    var _foregroundView: UIView!
    var _topLayoutGuideLength: UIView!
    var _fgScrollView: UIScrollView!
    var delegate: ATBlurScrollViewDelegate?
    override var frame:CGRect{
        set{
            self.setFrame(newValue)
        }
        get {
            return super.frame
        }
    }
    private var _bgScrollView: UIScrollView!
    private var _constraintView: UIView!
    private var _bgImageView: UIImageView!
    private var _blurredBgImageView: UIImageView!
    private var _topShadowLayer: CALayer!
    private var _bottomShadowLayer: CALayer!
    private var _foregroundContainerView: UIView!
    private var _topMaskImageView: UIImageView!
    
    
    init(frame:CGRect, backgroundImage:UIImage, blurredImage:UIImage?, viewDistanceFromBottom:CGFloat, foregroundView:UIView){
        super.init(frame: frame)
        
        _backgroundImage = backgroundImage
        if let blurImg = blurredImage {
            _blurredBackgroundImage = backgroundImage
        } else {
            _blurredBackgroundImage = backgroundImage.applyBlurWithRadius(BLUR_RADIUS, tintColor: BLUR_TINT_COLOR, saturationDeltaFactor: BLUR_DELTA_FACTOR, maskImage: nil)
        }
        _viewDistanceFromBottom = viewDistanceFromBottom
        _foregroundView = foregroundView
        
        self.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        
        self.constructBackgroundView()
        self.constructForegroundView()
        self.constructBottomShadow()
        self.constructTopShadow()
    }
    
    func scrollHorizontalRatio(ratio:CGFloat){
        _bgScrollView.setContentOffset(CGPointMake(MAX_BACKGROUND_MOVEMENT_HORIZONTAL + ratio * MAX_BACKGROUND_MOVEMENT_HORIZONTAL, _bgScrollView.contentOffset.y), animated: false)
    }
    
    func scrollVerticallyToOffset(offsetY: CGFloat){
        _fgScrollView.setContentOffset(CGPointMake(_fgScrollView.contentOffset.x, offsetY), animated: false)
    }
    
    func setFrame(frame:CGRect){
        super.frame = frame;
        let bound = CGRectOffset(frame, -frame.origin.x, -frame.origin.y)
        
        _bgScrollView?.frame = bound
        _bgScrollView?.contentSize = CGSizeMake(bound.size.width + MAX_BACKGROUND_MOVEMENT_HORIZONTAL, bound.size.height + MAX_BACKGROUND_MOVEMENT_VERTICAL);
        
        _bgScrollView?.setContentOffset(CGPointMake(MAX_BACKGROUND_MOVEMENT_HORIZONTAL, 0), animated: false)
        
        _constraintView?.frame = CGRectMake(0, 0, frame.size.width + MAX_BACKGROUND_MOVEMENT_HORIZONTAL, frame.size.height + MAX_BACKGROUND_MOVEMENT_VERTICAL)
        
        //foreground
        _foregroundContainerView?.frame = bound
        _fgScrollView?.frame = bound
        if let fgv = _foregroundView{
            _foregroundView?.frame = CGRectOffset(_foregroundView.bounds, (_fgScrollView.frame.size.width - _foregroundView.bounds.size.width)/2, _fgScrollView.frame.size.height - _fgScrollView.contentInset.top - _viewDistanceFromBottom)

        }
        
        if let fgs = _fgScrollView {
           _fgScrollView?.contentSize = CGSizeMake(bound.size.width, _foregroundView.frame.origin.y + _foregroundView.frame.size.height)
            _topShadowLayer?.frame = CGRectMake(0, 0, frame.size.width, _fgScrollView.contentInset.top + TOP_FADING_HEIGHT_HALF)
            
            _bottomShadowLayer?.frame = CGRectMake(0, bound.size.height - _viewDistanceFromBottom, bound.size.width, bound.size.height)
        }

        
        //shadows
        //[self createTopShadow];
 
        

        delegate?.blurScrollView!(self, didChangedToFrame: bound)
    }
    
    func setTopLayoutGuideLength(topLayoutGuideLength:CGFloat){
        if topLayoutGuideLength == 0 {return}
        _fgScrollView.contentInset = UIEdgeInsetsMake(topLayoutGuideLength, 0, 0, 0)
        _foregroundView.frame = CGRectOffset(_foregroundView.bounds, (_fgScrollView.frame.size.width - _foregroundView.bounds.size.width)/2, _fgScrollView.frame.size.height - _fgScrollView.contentInset.top - _viewDistanceFromBottom)
        
        _fgScrollView.contentSize = CGSizeMake(self.frame.size.width, -_foregroundView.frame.origin.y + _foregroundView.frame.size.height)
        
        _fgScrollView.setContentOffset(CGPointMake(0, -_fgScrollView.contentInset.top), animated: false)
        
        _foregroundContainerView.layer.mask = self.createTopMaskWithSize(CGSizeMake(_foregroundContainerView.frame.size.width, _foregroundContainerView.frame.size.height), startFadeAt: _fgScrollView.contentInset.top - TOP_FADING_HEIGHT_HALF, endAt: _fgScrollView.contentInset.top + TOP_FADING_HEIGHT_HALF, topColor: UIColor(white: 1.0, alpha: 0.0), botColor: UIColor(white: 1.0, alpha: 1.0))
        
    
        self.constructTopShadow()
    }
    
    func setViewDistanceFromBottom(viewDistanceFromBottom:CGFloat){
        _viewDistanceFromBottom = viewDistanceFromBottom
        _foregroundView.frame = CGRectOffset(_foregroundView.bounds, (_fgScrollView.frame.size.width - _foregroundView.bounds.size.width)/2, _fgScrollView.frame.size.height - _fgScrollView.contentInset.top - _viewDistanceFromBottom)
        _fgScrollView.contentSize = CGSizeMake(self.frame.size.width, _foregroundView.frame.origin.y + _foregroundView.frame.size.height)
        
        _bottomShadowLayer.frame = CGRectOffset(_bottomShadowLayer.bounds, 0, self.frame.size.height - _viewDistanceFromBottom)
    }
    
    func constructBackgroundView() {
        _bgScrollView = UIScrollView(frame: self.frame)
        _bgScrollView.userInteractionEnabled = false
        
        _bgScrollView.contentSize = CGSizeMake(self.frame.size.width + 2 * MAX_BACKGROUND_MOVEMENT_HORIZONTAL, self.frame.size.height + MAX_BACKGROUND_MOVEMENT_VERTICAL)
        
        self.addSubview(_bgScrollView)
        
        _constraintView = UIView(frame: CGRectMake(0, 0, self.frame.size.width + 2 * MAX_BACKGROUND_MOVEMENT_HORIZONTAL, self.frame.size.height + MAX_BACKGROUND_MOVEMENT_VERTICAL))
        
        _bgScrollView.addSubview(_constraintView)
        
        _bgImageView = UIImageView(image: _backgroundImage)
        _bgImageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        _bgImageView.contentMode = UIViewContentMode.ScaleAspectFill
        _constraintView.addSubview((_bgImageView))

        _blurredBgImageView = UIImageView(image: _blurredBackgroundImage)
        _blurredBgImageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        _blurredBgImageView.contentMode = UIViewContentMode.ScaleAspectFill
        _blurredBgImageView.alpha = 0
        _constraintView.addSubview(_blurredBgImageView)
        
        _constraintView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[bgImageView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: ["bgImageView":_bgImageView]))

        _constraintView.addConstraints((NSLayoutConstraint.constraintsWithVisualFormat("H:|[bgImageView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: ["bgImageView":_bgImageView])))
        
        _constraintView.addConstraints((NSLayoutConstraint.constraintsWithVisualFormat("V:|[blurredBgImageView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: ["blurredBgImageView":_blurredBgImageView])))
        _constraintView.addConstraints((NSLayoutConstraint.constraintsWithVisualFormat("H:|[blurredBgImageView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: ["blurredBgImageView":_blurredBgImageView])))
    }
    
    func setNewBackgroundImage(image:UIImage) {
        _bgImageView.image = image
        _blurredBackgroundImage = image.applyBlurWithRadius(BLUR_RADIUS, tintColor: BLUR_TINT_COLOR, saturationDeltaFactor: BLUR_DELTA_FACTOR, maskImage: nil)
        _blurredBgImageView.image = _blurredBackgroundImage
        _bgImageView.setNeedsDisplay()
        _blurredBgImageView.setNeedsDisplay()
    }
    
    func constructForegroundView() {
        _foregroundContainerView = UIView(frame: self.frame)
        self.addSubview(_foregroundContainerView)
        
        _fgScrollView = UIScrollView(frame: self.frame)
        _fgScrollView.delegate = self
        _fgScrollView.showsVerticalScrollIndicator = false
        _fgScrollView.showsHorizontalScrollIndicator = false
        _foregroundContainerView.addSubview(_fgScrollView)
        
        _foregroundView.frame = CGRectOffset(_foregroundView.bounds, (_fgScrollView.frame.size.width - _foregroundView.bounds.size.width)/2, _fgScrollView.frame.size.height - _viewDistanceFromBottom)
        _fgScrollView.addSubview(_foregroundView)
        _fgScrollView.contentSize = CGSizeMake(self.frame.size.width, _foregroundView.frame.origin.y + _foregroundView.frame.size.height)
    }

    

    func createTopMaskWithSize(size:CGSize, startFadeAt:CGFloat, endAt:CGFloat, topColor:UIColor, botColor:UIColor) -> CALayer {
        let top = startFadeAt/size.height;
        let bottom = endAt/size.height;
        
        var maskLayer = CAGradientLayer()
        maskLayer.anchorPoint = CGPointZero;
        maskLayer.startPoint = CGPointMake(0.5, 0.0);
        maskLayer.endPoint = CGPointMake(0.5, 1.0);
        
        let colors: [AnyObject] = [topColor.CGColor, topColor.CGColor, botColor.CGColor, botColor.CGColor]
        
        maskLayer.colors = colors
        
        maskLayer.locations = [0.0, top, bottom, 1.0]
        maskLayer.frame = CGRectMake(0, 0, size.width, size.height);
        return maskLayer;

    }
    
    func foregroundTapped(tapRecognizer:UITapGestureRecognizer){
        let tappedPoint = tapRecognizer.locationInView(_fgScrollView)
        if tappedPoint.y < _fgScrollView.frame.size.height {
            var ratio:CGFloat = _fgScrollView.contentOffset.y == -_fgScrollView.contentInset.top ? 1:0
            
            _fgScrollView.setContentOffset(CGPointMake(0, ratio * _foregroundView.frame.origin.y - _fgScrollView.contentInset.top), animated: true)
            
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView!) {
        var ratio = (scrollView.contentOffset.y + _fgScrollView.contentInset.top)/(_fgScrollView.frame.size.height - _fgScrollView.contentInset.top - _viewDistanceFromBottom)
        ratio = ratio < 0 ? 0 : ratio
        ratio = ratio > 1 ? 1 : ratio
        
        _bgScrollView.setContentOffset(CGPointMake(MAX_BACKGROUND_MOVEMENT_HORIZONTAL, ratio * MAX_BACKGROUND_MOVEMENT_VERTICAL), animated: false)
        _blurredBgImageView.alpha = ratio
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView!, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let point:CGPoint = targetContentOffset.memory
        var ratio = (point.y + _fgScrollView.contentInset.top)/(_fgScrollView.frame.size.height - _fgScrollView.contentInset.top - _viewDistanceFromBottom)
        
        if ratio > 0 && ratio < 1 {
            if velocity.y == 0 {
                ratio = ratio > 0.5 ? 1 : 0
            } else if velocity.y > 0 {
                ratio = ratio > 0.1 ? 1 : 0
            } else {
                ratio = ratio > 0.9 ? 1 : 0
            }
        }
        targetContentOffset.memory.y = ratio * _foregroundView.frame.origin.y - _fgScrollView.contentInset.top
        
    }
    
    func constructTopShadow(){
        _topShadowLayer?.removeFromSuperlayer()
        _topShadowLayer = self.createTopMaskWithSize(CGSizeMake(_foregroundContainerView.frame.size.width, _fgScrollView.contentInset.top + TOP_FADING_HEIGHT_HALF), startFadeAt: _fgScrollView.contentInset.top - TOP_FADING_HEIGHT_HALF, endAt: _fgScrollView.contentInset.top + TOP_FADING_HEIGHT_HALF, topColor: UIColor(white: 0, alpha: 0.15), botColor: UIColor(white: 0, alpha: 0))
        self.layer.insertSublayer(_topShadowLayer, above: _foregroundContainerView.layer)
    }
    
    func constructBottomShadow(){
        _bottomShadowLayer?.removeFromSuperlayer()
        _bottomShadowLayer = self.createTopMaskWithSize(CGSizeMake(self.frame.size.width, _viewDistanceFromBottom), startFadeAt: 0, endAt: _viewDistanceFromBottom, topColor: UIColor(white: 0, alpha: 0), botColor: UIColor(white: 0, alpha: 0.8))
        _bottomShadowLayer.frame = CGRectOffset((_bottomShadowLayer.bounds), 0, self.frame.size.height - _viewDistanceFromBottom)
        self.layer.insertSublayer(_bottomShadowLayer, below: _foregroundContainerView.layer)
    }

    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
        
    }
}
