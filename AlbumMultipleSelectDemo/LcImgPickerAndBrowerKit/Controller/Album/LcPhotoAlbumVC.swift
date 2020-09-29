//
//  LcPhotoAlbumVC.swift
//  AlbumMultipleSelectDemo
//
//  Created by 刘隆昌 on 2020/9/28.
//  Copyright © 2020 刘隆昌. All rights reserved.
//

import UIKit
import Photos

enum SelectStyle:Int{
    case check
    case number
}


class LcPhotoAlbumVC: LcBaseVC, PHPhotoLibraryChangeObserver, UICollectionViewDelegate, UICollectionViewDataSource {


        var isFirstSelectVideo:Bool = false
        var isFirstSelectPhoto:Bool = false
        
        
        
        
        var assetsFetchResult: PHFetchResult<PHAsset>?
        var maxSelectCount = 0
        var selectStyle:SelectStyle = .number
        // 剪裁大小
        var clipBounds: CGSize = CGSize(width: kScreenWidth, height: kScreenWidth)
        
        weak var photoAlbumDelegate: LcPhotoAlbumProtocol?
        
        private let cellIdentifier = "PhotoCollectionCell"
        private lazy var photoCollectionView: UICollectionView = {
            // 竖屏时每行显示4张图片
            let shape: CGFloat = 5
            let cellWidth: CGFloat = (kScreenWidth - 5 * shape) / 4
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.sectionInset = UIEdgeInsets(top: kNavigationTotalHeight, left: shape, bottom: 44+kHomeBarHeight, right: shape)
            flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
            flowLayout.minimumLineSpacing = shape
            flowLayout.minimumInteritemSpacing = shape
            //  collectionView
            let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight), collectionViewLayout: flowLayout)
            collectionView.backgroundColor = UIColor.white
            collectionView.scrollIndicatorInsets = UIEdgeInsets(top: kNavigationTotalHeight, left: 0, bottom: 44+kHomeBarHeight, right: 0)
            //  添加协议方法
            collectionView.delegate = self
            collectionView.dataSource = self
            //  设置 cell
            collectionView.register(LcPhotoCollectionViewCell.self, forCellWithReuseIdentifier: self.cellIdentifier)
            return collectionView
        }()
        
        private var bottomView = LcAlbumBottomView()
        
        private lazy var loadingView: UIView = {
            let view = UIView(frame: CGRect(x: 0, y: kNavigationTotalHeight, width: kScreenWidth, height: kScreenHeight-kNavigationTotalHeight))
            view.backgroundColor = UIColor.clear
            let loadingBackView = UIImageView(frame: CGRect(x: view.frame.width/2-54, y: view.frame.height/2-32-54, width: 108, height: 108))
            loadingBackView.image = UIImage.lcCreateImageWithColor(color: UIColor(white: 0, alpha: 0.8), size: CGSize(width: 108, height: 108))?.lcSetRoundedCorner(radius: 6)
            view.addSubview(loadingBackView)
            let loading = UIActivityIndicatorView(style: .large)
            loading.center = CGPoint(x: 54, y: 54)
            loading.startAnimating()
            loadingBackView.addSubview(loading)
            return view
        }()
        
        //  数据源
        private var photoData = LcPhotoDataSource()
        
        deinit {
            if kPhotoAlbumEnableDebugOn {
                print("=====================\(self)未内存泄露")
            }
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            if #available(iOS 11.0, *) {
                self.photoCollectionView.contentInsetAdjustmentBehavior = .never
            } else {
                self.automaticallyAdjustsScrollViewInsets = false
            }
            self.view.addSubview(self.photoCollectionView)
            self.initNavigation()
            self.setBottomView()
            self.getAllPhotos()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if self.photoData.dataChanged {
                self.photoCollectionView.reloadData()
                self.completedButtonShow()
            }
        }
        
        override var preferredStatusBarStyle: UIStatusBarStyle{
            return  .default
        }
        
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            self.photoData.dataChanged = false
        }
        
        var cateView:AlbumCategoryView!
        
        //  MARK:- private method
        private func initNavigation() {
            self.setNavTitle(title: "最近项目")
            self.view.bringSubviewToFront(self.naviView)
            weak var weakSelf:LcPhotoAlbumVC! = self
            if self.cateView == nil {
                let cateView = AlbumCategoryView.init(frame: CGRect.init(x: 0, y: kNavigationHeight+kStatusBarHeight, width: kScreenWidth, height: kScreenHeight-kHomeBarHeight))
                self.view.addSubview(cateView)
                self.cateView = cateView
                self.cateView.isHidden = true
            }
            
            self.titleBtnClosure = {()->Void in
                weakSelf.cateView.isHidden = !weakSelf.cateView.isHidden
                weakSelf.cateView.completeBlock = { (_ asset:PSAlbum) in
                    weakSelf.getPointerAlbumPhotos(asset)
                }
            };
            
            
        }
        
        
        
        
        
        private func setBottomView() {
            /**预览一组图片
            self.bottomView.leftClicked = { [unowned self] in
                self.gotoPreviewViewController(previewArray: self.photoData.seletedAssetArray, currentIndex: 0,souceType:1)
            }
            */
            self.bottomView.rightClicked = { [unowned self] in
                self.selectSuccess(fromeView: self.view, selectAssetArray: self.photoData.seletedAssetArray)
            }
            self.view.addSubview(self.bottomView)
        }
        
        private func getAllPhotos() {
            //  注意点！！-这里必须注册通知，不然第一次运行程序时获取不到图片，以后运行会正常显示。体验方式：每次运行项目时修改一下 Bundle Identifier，就可以看到效果。
            PHPhotoLibrary.shared().register(self)
            let status = PHPhotoLibrary.authorizationStatus()
            if status == .restricted || status == .denied {
                // 无权限
                // do something...
                if kPhotoAlbumEnableDebugOn {
                    print("无相册访问权限")
                }
                let alert = UIAlertController(title: nil, message: "请打开相册访问权限", preferredStyle: .alert)
                let cancleAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                alert.addAction(cancleAction)
                let goAction = UIAlertAction(title: "设置", style: .default, handler: { (action) in
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.openURL(url)
                    }
                })
                alert.addAction(goAction)
                self.present(alert, animated: true, completion: nil)
                return;
            }
            DispatchQueue.global(qos: .userInteractive).async {
                //  获取所有系统图片信息集合体
                let allOptions = PHFetchOptions()
                //  对内部元素排序，按照时间由远到近排序
                allOptions.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
                //  将元素集合拆解开，此时 allResults 内部是一个个的PHAsset单元
                /**
                    let fetchAssets = self.assetsFetchResult ?? PHAsset.fetchAssets(with: allOptions)
                    let fetchAssets = self.assetsFetchResult ?? PHAsset.fetchAssets(with: PHAssetMediaType.video, options: allOptions)
                 */
                
                let fetchAssets = self.assetsFetchResult ?? PHAsset.fetchAssets(with: allOptions)
                self.photoData.assetArray = fetchAssets.objects(at: IndexSet.init(integersIn: 0..<fetchAssets.count))
                if self.photoData.divideArray.count == 0 {
                    self.photoData.divideArray = Array(repeating: false, count: self.photoData.assetArray.count)
                    self.photoData.dataChanged = false
                }
                DispatchQueue.main.async {
                    self.photoCollectionView.reloadData()
                }
            }
        }
        
        
        
        private func getPointerAlbumPhotos(_ asset:PSAlbum) {
            //  注意点！！-这里必须注册通知，不然第一次运行程序时获取不到图片，以后运行会正常显示。体验方式：每次运行项目时修改一下 Bundle Identifier，就可以看到效果。
            PHPhotoLibrary.shared().register(self)
            let status = PHPhotoLibrary.authorizationStatus()
            if status == .restricted || status == .denied {
                // 无权限
                // do something...
                if kPhotoAlbumEnableDebugOn {
                    print("无相册访问权限")
                }
                let alert = UIAlertController(title: nil, message: "请打开相册访问权限", preferredStyle: .alert)
                let cancleAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                alert.addAction(cancleAction)
                let goAction = UIAlertAction(title: "设置", style: .default, handler: { (action) in
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.openURL(url)
                    }
                })
                alert.addAction(goAction)
                self.present(alert, animated: true, completion: nil)
                return;
            }
            
            
            DispatchQueue.global(qos: .userInteractive).async {
                //  获取所有系统图片信息集合体
                let allOptions = PHFetchOptions()
                //  对内部元素排序，按照时间由远到近排序
                allOptions.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
                //  将元素集合拆解开，此时 allResults 内部是一个个的PHAsset单元
                /**
                    let fetchAssets = self.assetsFetchResult ?? PHAsset.fetchAssets(with: allOptions)
                    let fetchAssets = self.assetsFetchResult ?? PHAsset.fetchAssets(with: PHAssetMediaType.video, options: allOptions)
                 */
                
                self.photoData.assetArray = GetAllAlbumsPicsTool.fetchAssets(inAssetCollection:asset.assetCollection, ascending: false)
                if self.photoData.divideArray.count == 0 {
                    self.photoData.divideArray = Array(repeating: false, count: self.photoData.assetArray.count)
                    self.photoData.dataChanged = false
                }
                DispatchQueue.main.async {
                    self.photoCollectionView.reloadData()
                }
            }
            
            
            
            
            
        }
        
        
        
        
        private func completedButtonShow() {
            if self.photoData.seletedAssetArray.count > 0 {
                self.bottomView.rightButtonTitle = "完成(\(self.photoData.seletedAssetArray.count))"
                self.bottomView.buttonIsEnabled = true
            } else {
                self.bottomView.rightButtonTitle = "完成"
                self.bottomView.buttonIsEnabled = false
            }
        }
        
        private func showLoadingView(inView: UIView) {
            inView.addSubview(loadingView)
        }
        private func hideLoadingView() {
            loadingView.removeFromSuperview()
        }
        
        // MARK:- handle events
        private func gotoPreviewViewController(previewArray: [PHAsset], currentIndex: Int,souceType:Int) {
            let previewVC = LcPhotoPreviewVC()
            previewVC.selectStyle = self.selectStyle
            previewVC.maxSelectCount = maxSelectCount
            previewVC.currentIndex = currentIndex
            previewVC.photoData = self.photoData
            previewVC.from = souceType
            previewVC.previewPhotoArray = previewArray
            previewVC.sureClicked = { [unowned self] (view: UIView, selectPhotos: [PHAsset]) in
                self.selectSuccess(fromeView: view, selectAssetArray: selectPhotos)
            }
            self.navigationController?.pushViewController(previewVC, animated: true)
        }
        
        private func gotoClipViewController(photoImage: UIImage) {
            let clipVC = LcPhotoClipVC()
            clipVC.clipBounds = self.clipBounds
            clipVC.photoImage = photoImage
            clipVC.sureClicked = { [unowned self] (clipPhoto: UIImage?) in
                if self.photoAlbumDelegate != nil, self.photoAlbumDelegate!.responds(to: #selector(LcPhotoAlbumProtocol.photoAlbum(clipPhoto:))) {
                    self.photoAlbumDelegate?.photoAlbum!(clipPhoto: clipPhoto)
                }
                self.dismiss(animated: true, completion: nil)
            }
            self.navigationController?.pushViewController(clipVC, animated: true)
        }
        
        private func selectPhotoCell(cell: LcPhotoCollectionViewCell, index: Int) {
            
            var isHaveSelectedOnes:Bool = false
            if photoData.divideArray.contains(true) == true {//有选中的
                isHaveSelectedOnes = true
            }
            
            photoData.divideArray[index] = !photoData.divideArray[index]
            let asset = photoData.assetArray[index]
            if photoData.divideArray[index] {
                if maxSelectCount != 0, photoData.seletedAssetArray.count >= maxSelectCount {
                    //超过最大数
                    cell.isChoose = false
                    photoData.divideArray[index] = !photoData.divideArray[index]
                    let alert = UIAlertController(title: nil, message: "您最多只能选择\(maxSelectCount)张照片", preferredStyle: .alert)
                    let action = UIAlertAction(title: "我知道了", style: .cancel, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                    photoCollectionView.reloadData()
                    return
                }
                photoData.seletedAssetArray.append(asset)
            } else {
                if let removeIndex = photoData.seletedAssetArray.index(of: asset) {
                    photoData.seletedAssetArray.remove(at: removeIndex)
                }
            }
            
            
            if photoData.divideArray.contains(true) == false && isHaveSelectedOnes == true{//没有选中的
    //            if (strongSelf.isFirstSelectPhoto == true || strongSelf.isFirstSelectVideo == true) && (strongSelf.photoData.divideArray.contains(true) == false || ){
    //                strongSelf.maxSelectCount = 9;
    //                strongSelf.isFirstSelectPhoto = false
    //                strongSelf.isFirstSelectVideo = false
    //            }
                self.maxSelectCount = 9;
                self.isFirstSelectPhoto = false
                self.isFirstSelectVideo = false
            }else{
                
                print("================")
            }
            
            
            photoCollectionView.reloadData()
            self.completedButtonShow()
        }
        
        
        
        
        
        private func selectSuccess(fromeView: UIView, selectAssetArray: [PHAsset]) {
            self.showLoadingView(inView: fromeView)
            var selectPhotos: [LcPhotoModel] = Array(repeating: LcPhotoModel(), count: selectAssetArray.count)
            let group = DispatchGroup()
            
            
            if selectAssetArray[0].mediaType == PHAssetMediaType.video{//选中的是视频
                
                /*得到选中视频的URL*/
                for i in 0 ..< selectAssetArray.count {
                    let asset = selectAssetArray[i]
                    group.enter()
                    let options = PHVideoRequestOptions.init()
                    options.version = PHVideoRequestOptionsVersion.current
                    options.deliveryMode = PHVideoRequestOptionsDeliveryMode.automatic
                    let manager = PHImageManager.default()
                    var urlUse : URL!
                    manager.requestAVAsset(forVideo: asset, options: options) { (asset:AVAsset?, audioMix:AVAudioMix?,info:[AnyHashable:Any]?) in
                        let urlAsset : AVURLAsset = asset as! AVURLAsset;
                        let url = urlAsset.url;
                        urlUse = url;
                        //let data = NSData.init(contentsOf: url);
                        print("选中视频的url: \(String(describing: urlUse))")
                        group.leave()
                    }
                }
                /*得到选中视频的图片*/
                for i in 0 ..< selectAssetArray.count {
                    let asset = selectAssetArray[i]
                    group.enter()
                    let photoModel = LcPhotoModel()
                    _ = LcCacheImgManager.default().requestThumbnailImage(for: asset, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                        photoModel.thumbnailImage = image
                    })
                    _ = LcCacheImgManager.default().requestPreviewImage(for: asset, progressHandler: nil, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                        var downloadFinined = true
                        if let cancelled = dictionry![PHImageCancelledKey] as? Bool {
                            downloadFinined = !cancelled
                        }
                        if downloadFinined, let error = dictionry![PHImageErrorKey] as? Bool {
                            downloadFinined = !error
                        }
                        if downloadFinined, let resultIsDegraded = dictionry![PHImageResultIsDegradedKey] as? Bool {
                            downloadFinined = !resultIsDegraded
                        }
                        if downloadFinined, let photoImage = image {
                            photoModel.originImage = photoImage
                            selectPhotos[i] = photoModel
                            group.leave()
                        }
                    })
                }
                
                /*任务都完成之后，得到通知*/
                group.notify(queue: DispatchQueue.main, execute: {
                    self.hideLoadingView()
                    if self.photoAlbumDelegate != nil {
                        if self.photoAlbumDelegate!.responds(to: #selector(LcPhotoAlbumProtocol.photoAlbum(selectPhotoAssets:))){
                            self.photoAlbumDelegate?.photoAlbum!(selectPhotoAssets: selectAssetArray)
                        }
                        if self.photoAlbumDelegate!.responds(to: #selector(LcPhotoAlbumProtocol.photoAlbum(selectPhotos:))) {
                            self.photoAlbumDelegate?.photoAlbum!(selectPhotos: selectPhotos)
                        }
                    }
                    self.dismiss(animated: true, completion: nil)
                })
                
                
            }
            
            
            
            if selectAssetArray[0].mediaType == PHAssetMediaType.image{//选中的图片
                
             
                /*得到选中视频的URL*/
                for i in 0 ..< selectAssetArray.count {
                    let asset = selectAssetArray[i]
                    group.enter()
                    let options = PHImageRequestOptions.init()
                    options.version = PHImageRequestOptionsVersion.current
                    options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
                    
                    let manager = PHImageManager.default()
                    
                    let targetSize = self.getThumbnailSize(originSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight))
                    let photoModel = LcPhotoModel()
                    
                    
                    manager.requestImage(for: asset, targetSize: targetSize, contentMode: PHImageContentMode.aspectFit, options: options) { (img:UIImage?,dic:[AnyHashable:Any]?) in
                        photoModel.thumbnailImage = img
                    }
                    
                    _ = LcCacheImgManager.default().requestPreviewImage(for: asset, progressHandler: nil, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                        var downloadFinined = true
                        if let cancelled = dictionry![PHImageCancelledKey] as? Bool {
                            downloadFinined = !cancelled
                        }
                        if downloadFinined, let error = dictionry![PHImageErrorKey] as? Bool {
                            downloadFinined = !error
                        }
                        if downloadFinined, let resultIsDegraded = dictionry![PHImageResultIsDegradedKey] as? Bool {
                            downloadFinined = !resultIsDegraded
                        }
                        if downloadFinined, let photoImage = image {
                            photoModel.originImage = photoImage
                            selectPhotos[i] = photoModel
                            group.leave()
                        }
                    })
                                  
                }
                
                /*任务都完成之后，得到通知*/
                group.notify(queue: DispatchQueue.main, execute: {
                    self.hideLoadingView()
                    if self.photoAlbumDelegate != nil {
                        if self.photoAlbumDelegate!.responds(to: #selector(LcPhotoAlbumProtocol.photoAlbum(selectPhotoAssets:))){
                            self.photoAlbumDelegate?.photoAlbum!(selectPhotoAssets: selectAssetArray)
                        }
                        if self.photoAlbumDelegate!.responds(to: #selector(LcPhotoAlbumProtocol.photoAlbum(selectPhotos:))) {
                            self.photoAlbumDelegate?.photoAlbum!(selectPhotos: selectPhotos)
                        }
                    }
                    self.dismiss(animated: true, completion: nil)
                })
                
                
            }
            
            
        }
        
        
        
        private func getThumbnailSize(originSize: CGSize) -> CGSize {
            let thumbnailWidth: CGFloat = (kScreenWidth - 5 * 5) / 4 * UIScreen.main.scale
            let pixelScale = CGFloat(originSize.width)/CGFloat(originSize.height)
            let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailWidth/pixelScale)
            
            return thumbnailSize
        }
        
        override func rightButtonClick(button: UIButton) {
            self.navigationController?.dismiss(animated: true)
        }
        
        // MARK:- delegate
        //  PHPhotoLibraryChangeObserver  第一次获取相册信息，这个方法只会进入一次
        func photoLibraryDidChange(_ changeInstance: PHChange) {
            guard self.photoData.assetArray.count == 0 else {return}
            DispatchQueue.main.async {
                self.getAllPhotos()
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return self.photoData.assetArray.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? LcPhotoCollectionViewCell, self.photoData.assetArray.count > indexPath.row else {return LcPhotoCollectionViewCell()}
            let asset = self.photoData.assetArray[indexPath.row]
          
            // 新建一个默认类型的图像管理器imageManager
            let imageManager = PHImageManager.default()
            // 新建一个PHImageRequestOptions对象
            let imageRequestOption = PHImageRequestOptions()
            // PHImageRequestOptions是否有效
            imageRequestOption.isSynchronous = true
            // 缩略图的压缩模式设置为无
            imageRequestOption.resizeMode = .none
            // 缩略图的质量为快速
            imageRequestOption.deliveryMode = .highQualityFormat
            // 按照PHImageRequestOptions指定的规则取出图片
            imageManager.requestImage(for: asset, targetSize: CGSize.init(width: 140, height: 140), contentMode: .aspectFill, options: imageRequestOption, resultHandler: {
                (result, _) -> Void in
                cell.photoImage = result!
            })
            
            
            if selectStyle == .number {
                if let Index = photoData.seletedAssetArray.index(of: asset) {
                    cell.layer.mask = nil
                    cell.isMasked_NotAllowSelect = false
                    
                    cell.selectNumber = Index
                    cell.selectButton.asyncSetImage(UIImage.lcCreateImageWithView(view: LcPhotoNavigationVC.lcGetSelectNuberView(index: "\(Index + 1)")), for: .selected)
                }else{
                    /**
                    cell.selectButton.isSelected = false
                    if maxSelectCount != 0, photoData.seletedAssetArray.count >= maxSelectCount{
                        let maskLayer = CALayer()
                        maskLayer.frame = cell.bounds
                        maskLayer.backgroundColor = UIColor.init(white: 1, alpha: 0.5).cgColor
                        cell.layer.mask = maskLayer
                    }else{
                        cell.layer.mask = nil
                    }
                     */
                    cell.selectButton.isSelected = false
                    if maxSelectCount != 0, (asset.mediaType == PHAssetMediaType.video && self.isFirstSelectPhoto == true) || (photoData.seletedAssetArray.count >= maxSelectCount){
                        let maskLayer = CALayer()
                        maskLayer.frame = cell.bounds
                        maskLayer.backgroundColor = UIColor.init(white: 1, alpha: 0.5).cgColor
                        cell.layer.mask = maskLayer
                        cell.isMasked_NotAllowSelect = true
                    }else{
                        cell.layer.mask = nil
                        cell.isMasked_NotAllowSelect = false
                    }
                    
                }
            }else{
                cell.isChoose = self.photoData.divideArray[indexPath.row]
            }
            cell.selectPhotoCompleted = { [weak self] in
                guard let strongSelf = self else {return}
                if cell.isMasked_NotAllowSelect == true {return}  //mask  蒙版   不允许选择
                
                
                
                let phAsset : PHAsset = strongSelf.photoData.assetArray[indexPath.item];
                if phAsset.mediaType == PHAssetMediaType.image {//第一张选中的是图片
                    print("图片");
                    strongSelf.maxSelectCount = 9;
                    strongSelf.isFirstSelectPhoto = true
                    strongSelf.isFirstSelectVideo = false
                    
                }
                if phAsset.mediaType == PHAssetMediaType.video {//第一张选中的是视频
                    print("视频");
                    strongSelf.maxSelectCount = 1;
                    strongSelf.isFirstSelectPhoto = false
                    strongSelf.isFirstSelectVideo = true
                }
                
                strongSelf.selectPhotoCell(cell: cell, index: indexPath.row)
            }
            
            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            
            let cell: LcPhotoCollectionViewCell = collectionView.cellForItem(at: indexPath) as! LcPhotoCollectionViewCell
            
            if cell.isMasked_NotAllowSelect {//不允许选择
                return
            }
            
            
            
            let phAsset : PHAsset = self.photoData.assetArray[indexPath.item];
            
            if phAsset.mediaType == PHAssetMediaType.video {
                
                self.showLoadingView(inView: self.view)
                var selectPhotos: [LcPhotoModel] = Array(repeating: LcPhotoModel(), count: 1)
                let group = DispatchGroup()
                
                /*得到选中视频的图片*/
                //for i in 0 ..< selectAssetArray.count {
                    //let asset = selectAssetArray[i]
                    group.enter()
                    let photoModel = LcPhotoModel()
                    _ = LcCacheImgManager.default().requestThumbnailImage(for: phAsset, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                        photoModel.thumbnailImage = image
                    })
                    _ = LcCacheImgManager.default().requestPreviewImage(for: phAsset, progressHandler: nil, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                        var downloadFinined = true
                        if let cancelled = dictionry![PHImageCancelledKey] as? Bool {
                            downloadFinined = !cancelled
                        }
                        if downloadFinined, let error = dictionry![PHImageErrorKey] as? Bool {
                            downloadFinined = !error
                        }
                        if downloadFinined, let resultIsDegraded = dictionry![PHImageResultIsDegradedKey] as? Bool {
                            downloadFinined = !resultIsDegraded
                        }
                        if downloadFinined, let photoImage = image {
                            photoModel.originImage = photoImage
                            selectPhotos[0] = photoModel
                            group.leave()
                        }
                    })
                //}
                
                
                
                
                group.enter()
                let options = PHVideoRequestOptions.init()
                options.version = PHVideoRequestOptionsVersion.current
                options.deliveryMode = PHVideoRequestOptionsDeliveryMode.automatic
                let manager = PHImageManager.default()
                var urlUse : URL!
                manager.requestAVAsset(forVideo: phAsset, options: options) { (asset:AVAsset?, audioMix:AVAudioMix?,info:[AnyHashable:Any]?) in
                    let urlAsset : AVURLAsset = asset as! AVURLAsset;
                    let url = urlAsset.url;
                    urlUse = url;
                    //let data = NSData.init(contentsOf: url);
                    print("选中视频的url: \(String(describing: urlUse))")
                    group.leave()
                }
                
                /*任务都完成之后，得到通知*/
                group.notify(queue: DispatchQueue.main, execute: {
                    self.hideLoadingView()
                    if self.photoAlbumDelegate != nil {
                        if self.photoAlbumDelegate!.responds(to: #selector(LcPhotoAlbumProtocol.photoAlbum(selectPhotoAssets:))){
                            self.photoAlbumDelegate?.photoAlbum!(selectPhotoAssets: [phAsset])
                        }
                        if self.photoAlbumDelegate!.responds(to: #selector(LcPhotoAlbumProtocol.photoAlbum(selectPhotos:))) {
                            self.photoAlbumDelegate?.photoAlbum!(selectPhotos: selectPhotos)
                        }
                    }
                    self.dismiss(animated: true, completion: nil)
                })
                
            }else if (phAsset.mediaType == PHAssetMediaType.image){//选中的是图片
                
                
                
                self.showLoadingView(inView: self.view)
                var selectPhotos: [LcPhotoModel] = Array(repeating: LcPhotoModel(), count: 1)
                let group = DispatchGroup()
                
                /*得到选中视频的图片*/
                group.enter()
                let photoModel = LcPhotoModel()
                _ = LcCacheImgManager.default().requestThumbnailImage(for: phAsset, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                    photoModel.thumbnailImage = image
                })
                _ = LcCacheImgManager.default().requestPreviewImage(for: phAsset, progressHandler: nil, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                    var downloadFinined = true
                    if let cancelled = dictionry![PHImageCancelledKey] as? Bool {
                        downloadFinined = !cancelled
                    }
                    if downloadFinined, let error = dictionry![PHImageErrorKey] as? Bool {
                        downloadFinined = !error
                    }
                    if downloadFinined, let resultIsDegraded = dictionry![PHImageResultIsDegradedKey] as? Bool {
                        downloadFinined = !resultIsDegraded
                    }
                    if downloadFinined, let photoImage = image {
                        photoModel.originImage = photoImage
                        selectPhotos[0] = photoModel
                        group.leave()
                    }
                })
                group.enter()
                
                
                
                let options = PHImageRequestOptions.init()
                options.version = PHImageRequestOptionsVersion.current
                options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
                
                let manager = PHImageManager.default()
                
                let targetSize = self.getThumbnailSize(originSize: CGSize(width: phAsset.pixelWidth, height: phAsset.pixelHeight))
                
                manager.requestImage(for: phAsset, targetSize: targetSize, contentMode: PHImageContentMode.aspectFit, options: options) { (img:UIImage?,dic:[AnyHashable:Any]?) in
                    photoModel.thumbnailImage = img
                }
                
                _ = LcCacheImgManager.default().requestPreviewImage(for: phAsset, progressHandler: nil, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                    var downloadFinined = true
                    if let cancelled = dictionry![PHImageCancelledKey] as? Bool {
                        downloadFinined = !cancelled
                    }
                    if downloadFinined, let error = dictionry![PHImageErrorKey] as? Bool {
                        downloadFinined = !error
                    }
                    if downloadFinined, let resultIsDegraded = dictionry![PHImageResultIsDegradedKey] as? Bool {
                        downloadFinined = !resultIsDegraded
                    }
                    if downloadFinined, let photoImage = image {
                        photoModel.originImage = photoImage
                        selectPhotos[0] = photoModel
                        group.leave()
                    }
                })
                            
                /*任务都完成之后，得到通知*/
                group.notify(queue: DispatchQueue.main, execute: {
                    self.hideLoadingView()
                    if self.photoAlbumDelegate != nil {
                        if self.photoAlbumDelegate!.responds(to: #selector(LcPhotoAlbumProtocol.photoAlbum(selectPhotoAssets:))){
                            self.photoAlbumDelegate?.photoAlbum!(selectPhotoAssets: [phAsset])
                        }
                        if self.photoAlbumDelegate!.responds(to: #selector(LcPhotoAlbumProtocol.photoAlbum(selectPhotos:))) {
                            self.photoAlbumDelegate?.photoAlbum!(selectPhotos: selectPhotos)
                        }
                    }
                    self.dismiss(animated: true, completion: nil)
                })
                
            }
            
        }

}




// 相册底部view
class LcAlbumBottomView: UIView {
    
    
     private lazy var previewButton: UIButton = {
         let button = UIButton(frame: CGRect(x: 12, y: 2, width: 60, height: 40))
         button.backgroundColor = UIColor.clear
         button.contentHorizontalAlignment = .left
         button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
         button.setTitle("预览", for: .normal)
         button.setTitleColor(UIColor(white: 0.5, alpha: 1), for: .disabled)
         button.setTitleColor(UIColor.white, for: .normal)
         button.addTarget(self, action: #selector(previewClick(button:)), for: .touchUpInside)
         button.isEnabled = false
         button.isHidden = true
         return button
     }()
     
    
    
    private lazy var sureButton: UIButton = {
        let button = UIButton(frame: CGRect(x: kScreenWidth-12-64, y: 6, width: 64, height: 32))
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle("完成", for: .normal)
        button.setBackgroundImage(UIImage.lcCreateImageWithColor(color: LcPhotoAlbumSkinColor, size: CGSize(width: 64, height: 32))?.lcSetRoundedCorner(radius: 4), for: .normal)
        button.setBackgroundImage(UIImage.lcCreateImageWithColor(color: LcPhotoAlbumSkinColor.withAlphaComponent(0.5), size: CGSize(width: 64, height: 32))?.lcSetRoundedCorner(radius: 4), for: .disabled)
        button.setTitleColor(UIColor(white: 0.5, alpha: 1), for: .disabled)
        button.setTitleColor(UIColor.white, for: .normal)
        button.addTarget(self, action: #selector(sureClick(button:)), for: .touchUpInside)
        button.isEnabled = false
        button.isHidden = true
        return button
    }()
    
    
    
    
    private lazy var sendButton: UIButton = {
        let button = UIButton(frame: CGRect(x: kScreenWidth-12-64, y: 6, width: 64, height: 32))
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle("发送", for: .normal)
        button.setBackgroundImage(UIImage.lcCreateImageWithColor(color: LcPhotoAlbumSkinColor, size: CGSize(width: 64, height: 32))?.lcSetRoundedCorner(radius: 4), for: .normal)
        button.setBackgroundImage(UIImage.lcCreateImageWithColor(color: LcPhotoAlbumSkinColor.withAlphaComponent(0.5), size: CGSize(width: 64, height: 32))?.lcSetRoundedCorner(radius: 4), for: .disabled)
        button.setTitleColor(UIColor(white: 1, alpha: 0.8), for: .disabled)
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 3;
        button.layer.masksToBounds = true
        button.backgroundColor = UIColor.init(red: 255/255.0, green: 115/255.0, blue: 77/255.0, alpha: 1)
        button.addTarget(self, action: #selector(sendBtnAction(_:)), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    
    @objc func sendBtnAction(_ btn:UIButton){
        if rightClicked != nil {
            rightClicked!()
        }
    }
    
    
    
    private lazy var originalPictureBtn: UIButton = {
        let button = UIButton(frame: CGRect(x: 12, y: 2, width: 70, height: 40))
        button.backgroundColor = UIColor.clear
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle("原图", for: .normal)
        
        button.setImage(UIImage.init(named: "originalSelBtn"), for: .selected)
        button.setImage(UIImage.init(named: "originalImgBtn"), for: .normal)
        
        button.setTitleColor(UIColor.init(red: 51/255.0, green:  51/255.0, blue:  51/255.0, alpha: 1), for: .disabled)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        button.setTitleColor(UIColor.white, for: .normal)
        button.addTarget(self, action: #selector(originalImageBtnAction(_:)), for: .touchUpInside)
        button.isEnabled = true
        return button
    }()
    
    @objc func originalImageBtnAction(_ btn:UIButton){
        print("原图")
        
        btn.isSelected = !btn.isSelected
        
    }
    
    
    var leftButtonTitle: String? {
        didSet {
            self.previewButton.setTitle(leftButtonTitle, for: .normal)
        }
    }
    
    var rightButtonTitle: String? {
        didSet {
            self.sureButton.setTitle(rightButtonTitle, for: .normal)
            self.sendButton.setTitle("发送", for: .normal)
        }
    }
    
    var buttonIsEnabled = false {
        didSet {
            self.previewButton.isEnabled = buttonIsEnabled
            self.sureButton.isEnabled = buttonIsEnabled
            self.sendButton.isEnabled = buttonIsEnabled
        }
    }
    
    // 预览闭包
    var leftClicked: (() -> Void)?
    
    // 完成闭包
    var rightClicked: (() -> Void)?
    
    enum LcAlbumBottomViewType {
        case normal, noPreview
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: kScreenHeight-kHomeBarHeight-44, width: kScreenWidth, height: 44+kHomeBarHeight), type: .normal)
    }
    
    convenience init(type: LcAlbumBottomViewType) {
        self.init(frame: CGRect(x: 0, y: kScreenHeight-kHomeBarHeight-44, width: kScreenWidth, height: 44+kHomeBarHeight), type: type)
    }
    
    convenience override init(frame: CGRect) {
        self.init(frame: frame, type: .normal)
    }
    
    init(frame: CGRect, type: LcAlbumBottomViewType) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        if type == .normal {
            self.addSubview(self.previewButton)
            
            self.addSubview(self.originalPictureBtn)
        }
        
        self.addSubview(self.sureButton)
        self.addSubview(self.sendButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: handle events
    @objc func previewClick(button: UIButton) {
        if leftClicked != nil {
            leftClicked!()
        }
    }
    
    @objc func sureClick(button: UIButton) {
        if rightClicked != nil {
            rightClicked!()
        }
    }
}



