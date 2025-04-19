import SwiftUI
import PhotosUI

/**
 * 图片选择器 - 使用PhotosUI框架
 * 用于从相册选择单张或多张图片
 */
struct PHImagePicker: UIViewControllerRepresentable {
    /// 选中的图片数组
    @Binding var selectedImages: [UIImage]
    /// 完成选择后的回调
    var completion: ([UIImage]) -> Void
    /// 最大选择数量
    var maxSelectionCount: Int = 9
    
    /**
     * 创建UI控制器
     */
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = maxSelectionCount
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    /**
     * 更新UI控制器
     */
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    /**
     * 创建协调器
     */
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    /**
     * 协调器类，处理图片选择结果
     */
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHImagePicker
        
        init(parent: PHImagePicker) {
            self.parent = parent
        }
        
        /**
         * 处理图片选择完成事件
         */
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard !results.isEmpty else {
                return
            }
            
            var images: [UIImage] = []
            let dispatchGroup = DispatchGroup()
            
            for result in results {
                dispatchGroup.enter()
                
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        defer { dispatchGroup.leave() }
                        
                        if let image = image as? UIImage {
                            // 在实际应用中可能需要压缩图片
                            let processedImage = self.processImage(image)
                            images.append(processedImage)
                        } else if let error = error {
                            print("图片加载错误: \(error.localizedDescription)")
                        }
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.parent.selectedImages = images
                self.parent.completion(images)
            }
        }
        
        /**
         * 处理图片，进行压缩等操作
         */
        private func processImage(_ image: UIImage) -> UIImage {
            // 如果图片太大，进行压缩
            if let resizedImage = self.resizeImage(image, targetSize: 1080) {
                return resizedImage
            }
            return image
        }
        
        /**
         * 调整图片大小
         */
        private func resizeImage(_ image: UIImage, targetSize: CGFloat) -> UIImage? {
            let originalSize = image.size
            
            // 如果图片尺寸已经足够小，不需要调整
            if originalSize.width <= targetSize && originalSize.height <= targetSize {
                return image
            }
            
            // 计算新的尺寸，保持宽高比
            var newSize: CGSize
            
            if originalSize.width > originalSize.height {
                let ratio = targetSize / originalSize.width
                newSize = CGSize(width: targetSize, height: originalSize.height * ratio)
            } else {
                let ratio = targetSize / originalSize.height
                newSize = CGSize(width: originalSize.width * ratio, height: targetSize)
            }
            
            // 渲染新图片
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage
        }
    }
} 