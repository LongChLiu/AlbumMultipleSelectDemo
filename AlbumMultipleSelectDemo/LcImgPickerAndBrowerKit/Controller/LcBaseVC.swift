//
//  LcBaseVC.swift
//  AlbumMultipleSelectDemo
//
//  Created by 刘隆昌 on 2020/9/28.
//  Copyright © 2020 刘隆昌. All rights reserved.
//

import UIKit

class LcBaseVC: UIViewController {

    let naviView = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: kNavigationTotalHeight))
        lazy var leftButton: UIButton = {
            let leftButton = UIButton()
            leftButton.frame = CGRect(x: 20, y: kStatusBarHeight, width: 50, height: kNavigationHeight)
            leftButton.backgroundColor = UIColor.clear
            leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            leftButton.titleLabel?.textColor = UIColor.init(red: 102/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1)
            leftButton.setTitleColor(UIColor.init(red: 102/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1), for: .normal)
            leftButton.addTarget(self, action: #selector(rightButtonClick(button:)), for: .touchUpInside)
            leftButton.setTitle("取消", for: .normal)
            return leftButton
        }()
        
        /**
            lazy var titleLabel: UILabel = {
                let titleLabel = UILabel(frame: CGRect(x: ZYScreenWidth/2-50, y: ZYStatusBarHeight, width: 100, height: ZYNavigationHeight))
                titleLabel.textAlignment = .center
                titleLabel.textColor = UIColor.init(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1)
                titleLabel.font = UIFont.systemFont(ofSize: 17)
                return titleLabel
            }()
         */
        
        lazy var titleBtn: UIButton = {
            let btn = UIButton.init(type: .custom)
            btn.frame = CGRect(x: kScreenWidth/2-50, y: kStatusBarHeight, width: 100, height: kNavigationHeight)
            btn.setTitleColor(UIColor.init(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1), for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            btn.setImage(UIImage.init(named: "assetMore"), for: .normal)
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 85, bottom: 0, right: 0)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
            btn.addTarget(self, action: #selector(LcBaseVC.titleBtnAction(_:)), for: .touchUpInside)
            return btn
        }()
        
        var titleBtnClosure:(()->Void)! = nil
        
        @objc func titleBtnAction(_ btn:UIButton){
            if self.titleBtnClosure != nil {
                self.titleBtnClosure()
            }
        }
        
        
        override public func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
            self.navigationController?.navigationBar.isHidden = true
            self.setNavigationView()
        }
        
        fileprivate func setNavigationView() {
            naviView.backgroundColor = UIColor.white
            self.view.addSubview(naviView)
            naviView.addSubview(leftButton)
        }
        
        func setNavTitle(title: String) {
            /**
                        titleLabel.text = title
                        if !titleLabel.isDescendant(of: naviView) {
                            naviView.addSubview(titleLabel)
                        }
             */
            titleBtn.setTitle(title, for: .normal)
            if !titleBtn.isDescendant(of: naviView) {
                naviView.addSubview(titleBtn)
            }
        }
        
        func setRightTextButton(text: String, color: UIColor) {
    //        leftButton.setTitle(text, for: .normal)
    //        leftButton.setTitleColor(color, for: .normal)
    //        naviView.addSubview(leftButton)
        }
        
        func setRightImageButton(normalImage: UIImage?, selectedImage: UIImage?, isSelected: Bool) {
            leftButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 13, bottom: 10, right: 13)
            leftButton.asyncSetImage(normalImage, for: .normal)
            leftButton.asyncSetImage(selectedImage, for: .selected)
            leftButton.isSelected = isSelected
            naviView.addSubview(leftButton)
        }
        
        @objc func backClick(button: UIButton) {
            if self.presentationController != nil{
                //self.dismiss(animated: true, completion: nil)
                //Pop到照片选择页面
                self.navigationController!.popViewController(animated: true)
            }else{
                self.navigationController!.popViewController(animated: true)
            }
        }
        
        @objc func rightButtonClick(button: UIButton) {
            
        }
        

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
