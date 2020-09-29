//
//  AlbumCategoryView.swift
//  ZYImagePickerAndBrower
//
//  Created by 刘隆昌 on 2020/9/28.
//  Copyright © 2020 ZY. All rights reserved.
//

import UIKit


let assetCategoryID = "assetCategoryID"


typealias AlbumCateSelectClosure = (_ album:PSAlbum)->Void

class AlbumCategoryView: UIView,UIGestureRecognizerDelegate {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var completeBlock:AlbumCateSelectClosure! = nil
    
    var dataArray:[PSAlbum] = []
    var tabView:UITableView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.init(white: 0, alpha: 0.2)
        
        let tabView = UITableView.init(frame: CGRect.init(x: 0, y: 0, width: kScreenWidth, height: 295), style: .plain)
        self.addSubview(tabView)
        tabView.backgroundColor = UIColor.white
        tabView.delegate = self
        tabView.dataSource = self
        tabView.showsVerticalScrollIndicator = false
        tabView.showsHorizontalScrollIndicator = false
        tabView.register(AssetCategoryCell.self, forCellReuseIdentifier: assetCategoryID)
        self.tabView = tabView
        
        
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(AlbumCategoryView.tapAction(_:)))
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
        
        getAllAlbums()
    }
    
    func getAllAlbums(){
        self.dataArray = GetAllAlbumsPicsTool.fetchPhotoAblums()        
        self.tabView.reloadData()
    }
    
    @objc func tapAction(_ tap:UITapGestureRecognizer){
        self.isHidden = true
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let _ : AlbumCategoryView = gestureRecognizer.view as? AlbumCategoryView {
            let point = touch.location(in: self)
            if self.tabView.frame.contains(point){
                return false
            }
        }
        
        return true
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let cls = NSClassFromString("UITableView"),otherGestureRecognizer.view!.isKind(of: cls) {
            return true
        }
        
        return true
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension AlbumCategoryView:UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: assetCategoryID, for: indexPath) as! AssetCategoryCell
        
        let psAlbum = self.dataArray[indexPath.row]
        let psName = psAlbum.name
        let psCnt = psAlbum.count
        let asset = psAlbum.headImageAsset
        cell.selectionStyle = .none
        
        DispatchQueue.global().async {
            GetAllAlbumsPicsTool.requestThumbImage(for: asset!, targetSize: CGSize.init(width: 52, height: 52)) { (img:UIImage?,dic:[AnyHashable:Any]?) in
                DispatchQueue.main.async {
                    if let imgUse = img{
                        cell.setContent(img: imgUse, title: psName ?? "", num: psCnt ?? 0)
                    }
                }
            }
        }
        
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {        
        let psAlbum = self.dataArray[indexPath.row]
        if self.completeBlock != nil {
            self.completeBlock(psAlbum)
        }
        self.isHidden = true
    }
    
    
    
}
