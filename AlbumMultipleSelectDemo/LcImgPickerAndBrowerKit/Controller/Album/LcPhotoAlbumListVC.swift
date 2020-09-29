//
//  LcPhotoAlbumListVC.swift
//  AlbumMultipleSelectDemo
//
//  Created by 刘隆昌 on 2020/9/28.
//  Copyright © 2020 刘隆昌. All rights reserved.
//

import UIKit
import Photos

class LcPhotoAlbumListVC: LcBaseVC, UITableViewDelegate, UITableViewDataSource {

        weak var photoAlbumDelegate: LcPhotoAlbumProtocol?
        
        private var albumsList: [(assetCollection:PHAssetCollection, assetsFetchResult: PHFetchResult<PHAsset>)] = []
        private lazy var albumTableView: UITableView = {
            let tableView = UITableView(frame: CGRect(x: 0, y: kNavigationTotalHeight, width: kScreenWidth, height: kScreenHeight-kNavigationTotalHeight), style: .plain)
            tableView.backgroundColor = UIColor.white
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            return tableView
        }()
        
        deinit {
            if kPhotoAlbumEnableDebugOn {
                print("=====================\(self)未内存泄露")
            }
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
            self.initNavigation()
            self.view.addSubview(albumTableView)
            self.getAllAlbum()
        }
        
        //  MARK: - private method
        private func initNavigation() {
            self.setNavTitle(title: "照片")
            self.view.bringSubviewToFront(self.naviView)
        }
        
        override func rightButtonClick(button: UIButton) {
            self.navigationController?.dismiss(animated: true)
        }
        
        private func getAllAlbum() {//.smartAlbum
            DispatchQueue.global(qos: .userInteractive).async {
                let fetchResult = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: .albumRegular, options: nil)
                fetchResult.enumerateObjects({ [weak self] (assetCollection, index, nil) in
                    guard let strongSelf = self else {return}
                    let allOptions = PHFetchOptions()
                    allOptions.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
                    let assetsFetchResult = PHAsset.fetchAssets(in: assetCollection, options: allOptions)
                    guard assetsFetchResult.count <= 0 else {
                        
    //                    let assetItem = (assetCollection, assetsFetchResult)
    //                    if assetCollection.assetCollectionSubtype == .smartAlbumVideos || assetCollection.assetCollectionSubtype == .smartAlbumSlomoVideos {
    //                        return
    //                    }
    //                    if assetCollection.assetCollectionSubtype == .smartAlbumUserLibrary {
    //                        strongSelf.albumsList.insert(assetItem, at: 0)
    //                    } else {
    //                        strongSelf.albumsList.append(assetItem)
    //                    }
    //                    return
                        
                        let assetItem = (assetCollection, assetsFetchResult)
                        if assetCollection.assetCollectionSubtype == .smartAlbumVideos || assetCollection.assetCollectionSubtype == .smartAlbumSlomoVideos {
                            if assetCollection.assetCollectionSubtype == .smartAlbumUserLibrary {
                                strongSelf.albumsList.insert(assetItem, at: 0)
                            } else {
                                strongSelf.albumsList.append(assetItem)
                            }
                        }else{
                            return
                        }
                        
                        return
                        
                    }
                })
                DispatchQueue.main.async {
                    self.albumTableView.reloadData()
                }
            }
        }
        
        
        //  MARK: - delegate
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return albumsList.count
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 60
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let album: PHAssetCollection = albumsList[indexPath.row].assetCollection
            
            var albumsCell: LcAlbumCell? = tableView.dequeueReusableCell(withIdentifier: "AlbumsCell") as? LcAlbumCell
            if albumsCell == nil {
                albumsCell = LcAlbumCell(style: .default, reuseIdentifier: "AlbumsCell")
            }
            albumsCell?.albumName = album.localizedTitle
            let photoResult = PHAsset.fetchAssets(in: album, options: nil)
            if photoResult.count != 0 {
                let asset = photoResult.lastObject
                _ = LcCacheImgManager.default().requestThumbnailImage(for: asset!, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                    albumsCell?.albumImage = image
                })
            }
            return albumsCell!
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            guard albumsList.count > indexPath.row else {return}
            tableView.deselectRow(at: indexPath, animated: true)
            let assetsFetchResult = albumsList[indexPath.row].assetsFetchResult
            let photoAlbumViewController = LcPhotoAlbumVC()
            photoAlbumViewController.assetsFetchResult = assetsFetchResult
            photoAlbumViewController.photoAlbumDelegate = self.photoAlbumDelegate
            //photoAlbumViewController.type = self.type
            self.navigationController?.pushViewController(photoAlbumViewController, animated: true)
        }
    

}





private class LcAlbumCell: UITableViewCell {
    
    var albumImage: UIImage? {
        didSet {
            albumImageView.asyncSetImage(albumImage)
        }
    }
    
    var albumName: String? {
        didSet {
            albumNameLabel.text = albumName
        }
    }
    
    private lazy var cutLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor(white: 223/255.0, alpha: 1)
        return line
    }()
    
    private let albumImageView = UIImageView()
    private let albumNameLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.accessoryType = .disclosureIndicator
        albumImageView.contentMode = .scaleAspectFill
        albumImageView.clipsToBounds = true
        self.contentView.addSubview(albumImageView)
        self.contentView.addSubview(albumNameLabel)
        self.contentView.addSubview(cutLine)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let size = self.frame.size
        albumImageView.frame = CGRect(x: 0, y: 0, width: size.height, height: size.height)
        albumNameLabel.frame = CGRect(x: size.height+10, y: 0, width: 100, height: size.height)
        cutLine.frame = CGRect(x: 0, y: size.height-0.5, width: size.width, height: 0.5)
    }
}


