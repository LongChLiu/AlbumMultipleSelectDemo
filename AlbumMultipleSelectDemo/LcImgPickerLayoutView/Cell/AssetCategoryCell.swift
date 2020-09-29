//
//  AssetCategoryCell.swift
//  ZYImagePickerAndBrower
//
//  Created by 刘隆昌 on 2020/9/28.
//  Copyright © 2020 ZY. All rights reserved.
//

import UIKit

class AssetCategoryCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    var imgView:UIImageView!
    var titleLabel:UILabel!
    var numberLabel:UILabel!
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let img = UIImageView.init(frame: CGRect.init(x: 16, y: 10, width: 52, height: 52))
        contentView.addSubview(img)
        self.imgView = img
        img.backgroundColor = .lightGray
        img.layer.cornerRadius = 5
        img.layer.masksToBounds = true
        
        let titleLabel = UILabel.init(frame: CGRect.init(x: img.frame.maxX+14, y: img.frame.minY + 1, width: 200, height: 23))
        contentView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.init(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1)
        self.titleLabel = titleLabel
        
        let numberLabel = UILabel.init(frame: CGRect.init(x: img.frame.maxX+14, y: img.frame.maxY - 22, width: 200, height: 20))
        contentView.addSubview(numberLabel)
        numberLabel.font = UIFont.systemFont(ofSize: 14)
        numberLabel.textColor = UIColor.init(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1)
        self.numberLabel = numberLabel
    }
    
    
    func setContent(img:UIImage,title:String,num:Int){
        self.imgView.image = img
        self.titleLabel.text = title
        self.numberLabel.text = "\(num)"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
