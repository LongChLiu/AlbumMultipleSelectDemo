//
//  ViewController.swift
//  AlbumMultipleSelectDemo
//
//  Created by 刘隆昌 on 2020/9/28.
//  Copyright © 2020 刘隆昌. All rights reserved.
//

import UIKit

class ViewController: UIViewController,LcPhotoAlbumProtocol {
    
    var imgPickerView = LcImgPickerLayoutView.init(frame: CGRect.init(x: 30, y: 100, width: kScreenWidth-60, height: 349))

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        weak var weakSelf:ViewController! = self
        self.view.backgroundColor = .white
        self.view.addSubview(imgPickerView)
        imgPickerView.backgroundColor = .lightGray
        imgPickerView.addCallBack = { () in
            weakSelf.doBtnAction(nil)
        }
        
        
        let doBtn = UIButton.init(type: .custom)
        view.addSubview(doBtn)
        doBtn.frame = CGRect.init(x: 100, y: imgPickerView.frame.maxY+50, width: kScreenWidth-100*2, height: 40)
        doBtn.addTarget(self, action: #selector(ViewController.doBtnAction(_:)), for: .touchUpInside)
        doBtn.setTitle("选择图片", for: .normal)
        doBtn.setTitleColor(.black, for: .normal)
    }
    
    func photoAlbum(selectPhotos: [LcPhotoModel]) {
        weak var weakSelf:ViewController! = self
        imgPickerView.dataSource = selectPhotos
        imgPickerView.numberOfLine = 4
        imgPickerView.reloadView()
    }

    @objc func doBtnAction(_ btn:UIButton?){
        
        let photoAlbumVC = LcPhotoNavigationVC(photoAlbumDelegate: self)    //初始化需要设置代理对象
        photoAlbumVC.maxSelectCount = 9   //最大可选择张数
        photoAlbumVC.modalPresentationStyle = .fullScreen
        self.present(photoAlbumVC, animated: true, completion: nil)
        
        
    }

}

