//
//  GetAllAlbumsPicsTool.swift
//  ZYImagePickerAndBrower
//
//  Created by 刘隆昌 on 2020/9/28.
//  Copyright © 2020 ZY. All rights reserved.
//

import UIKit
import Photos


class GetAllAlbumsPicsTool: NSObject {
    
    
    
    /**
     获取所有的相册
     
     - returns: 返回相册数组
     */
    static func fetchPhotoAblums() -> Array<PSAlbum> {
        
        var albums = Array<PSAlbum>()
        
        var  recentProjectBringFirst:PSAlbum!
        
        // 获取所有的智能相册
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        smartAlbums.enumerateObjects({ (collection, _, _) in
            
            /**
                            // 过滤掉'最近添加'
                            if collection.assetCollectionSubtype != .smartAlbumRecentlyAdded {
                                let assets = fetchAssets(inAssetCollection: collection, ascending: false)
                                // 过滤掉空相册
                                if assets.count > 0 {
                                    
                                    var album = PSAlbum()
                                    album.name = collection.localizedTitle
                                    album.count = assets.count
                                    album.headImageAsset = assets.first
                                    album.assetCollection = collection
                                    
                                    albums.append(album)
                                }
                            }
             */
            
            if collection.assetCollectionSubtype != .smartAlbumRecentlyAdded && collection.assetCollectionSubtype.rawValue != 1000000201 {
                
                let assets = fetchAssets(inAssetCollection: collection, ascending: false)
                // 过滤掉空相册
                if assets.count > 0 {
                    
                    var album = PSAlbum()
                    album.name = collection.localizedTitle
                    if album.name == "最近项目" {
                        recentProjectBringFirst = album
                    }
                    album.count = assets.count
                    album.headImageAsset = assets.first
                    album.assetCollection = collection
                    albums.append(album)
                }
                
                
            }
            
            
            
        })
        
        
        
        
        // 获取所有的用户自定义相册
        let userAlbums = PHAssetCollection.fetchTopLevelUserCollections(with: nil)
        userAlbums.enumerateObjects({ (collection, _, _) in
                
            let assets = fetchAssets(inAssetCollection: collection as! PHAssetCollection, ascending: false)
            // 过滤掉空相册
            if assets.count > 0 {
                var album = PSAlbum()
                album.name = (collection as! PHAssetCollection).localizedTitle
                album.count = assets.count
                album.headImageAsset = assets.first
                album.assetCollection = collection as? PHAssetCollection
                albums.append(album)
            }
            
        })
        
        
        
        let arr:NSMutableArray = NSMutableArray.init(array: albums)
        var idxKey:Int = 0
        for (idx,obj) in albums.enumerated() {
            if obj.name == recentProjectBringFirst.name {
                idxKey = idx
            }
        }
        arr.exchangeObject(at: idxKey, withObjectAt: 0)
        
        
        
        return arr as! [PSAlbum]
        
    }


    /**
     获取系统相册中所有照片对象
     - parameter ascending: 是否按时间升序排列
     - returns: 照片对象数组
     */
    static func fetchAllPhotoAssetsInPhotoLibraryOrderByAscending(_ ascending: Bool) -> Array<PHAsset> {
     
        var assets = Array<PHAsset>()
        
        let option = PHFetchOptions()
        option.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: ascending)]
        
        let result = PHAsset.fetchAssets(with: option)
        result.enumerateObjects({ (asset, _, _) in
            assets.append(asset)
        })
        
        return assets;
        
    }
     

    /**
     获取特定相册中的所有照片对象
     
     - parameter collection: 相册对象
     - parameter ascending:  是否按时间升序排列
     
     - returns: 照片对象数组
     */
    static func fetchAssets(inAssetCollection collection: PHAssetCollection, ascending: Bool) -> Array<PHAsset> {
        
        var assets = Array<PHAsset>()
        
        let option = PHFetchOptions()
        option.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: ascending)]
        
        let result = PHAsset.fetchAssets(in: collection, options: option)
        result.enumerateObjects ({ (asset, _, _) in
            assets.append(asset)
        })
        
        return assets
    }


    /**
     获取缩略图
     
     - parameter asset:      图像对象
     - parameter targetSize: 缩略图大小，以 pt 为单位（不必考虑 px）
     - parameter completion: 完成后的回调，返回获取到的 UIImage 对象
     */
    static func requestThumbImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        
        let option = PHImageRequestOptions()
        
        option.version = .current
        option.resizeMode = .fast
        option.isNetworkAccessAllowed = false
        
        // 因为系统API中的 targetSize 以 px 为单位，所以需要对传入的参数进行转化，传入的参数不必考虑这个问题。
        let scale = UIScreen.main.scale
        let size = CGSize(width: targetSize.width * scale, height: targetSize.height * scale)
        
        PHCachingImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: option) { (image, info) in
            
            if let info = info {
                // 只有在获得高质量照片后，才执行回调（因为当前闭包可能会被调用多次）
                let isDegraded = info[PHImageResultIsDegradedKey] as? Bool
                if isDegraded != true {
                    // 执行回调，将获得到的图片传出
                    completion(image, info)
                }
                
            }
            
        }
        
    }


    /**
     获取原图
     
     - parameter asset:      图像对象
     - parameter completion: 完成后的回调，返回获取到的 UIImage 对象
     */
    static func requestOriginalImage(for asset: PHAsset, completion: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        
        let option = PHImageRequestOptions()
        
        option.version = .current
        option.resizeMode = .none
        option.deliveryMode = .highQualityFormat
        option.isNetworkAccessAllowed = false
        
        PHCachingImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: option) { (image, info) in
            if let info = info {
                // 只有在获得高质量照片后，才执行回调（因为当前闭包可能会被调用多次）
                let isDegraded = info[PHImageResultIsDegradedKey] as? Bool
                if isDegraded != true {
                    // 执行回调，将获得到的图片传出
                    completion(image, info)
                    
                }
                
            }
        }
        
    }
    
    

}





/**
 *  相册模型
 */
struct PSAlbum {
    
    var _name:String! = nil
    var name: String!{
        get{
            if _name == "Selfies" {
                return "自拍"
            }else if _name == "Panoramas"{
                return "全景图片"
            }else if _name == "Videos"{
                return "视频"
            }else if _name == "Screenshots"{
                return "截屏"
            }else if _name == "Recents"{
                return "最近项目"
            }else if _name == "Animated"{
                return "动图"
            }else if _name == "Favorites"{
                return "个人收藏"
            }else if _name == "Bursts"{
                return "连拍快照"
            }else if _name == "Live Photos"{
                return "实况照片"
            }
            return _name
        }
        set{
            _name = newValue
        }
    } // 相册名字
    
    
    var count: Int! // 相册里面照片数量
    var headImageAsset: PHAsset! // 相册里面第一张照片（作为封面）
    var assetCollection: PHAssetCollection! // 相册对应的 PHAssetCollection 对象
    
}


