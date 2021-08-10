/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

struct PhotoManagerNotification {
    // Notification when new photo instances are added
    static let contentAdded = Notification.Name("com.raywenderlich.GooglyPuff.PhotoManagerContentAdded")
    // Notification when content updates (i.e. Download finishes)
    static let contentUpdated = Notification.Name("com.raywenderlich.GooglyPuff.PhotoManagerContentUpdated")
}

struct PhotoURLString {
    // Photo Credit: Devin Begley, http://www.devinbegley.com/
    static let overlyAttachedGirlfriend = "https://imgur.com/ZUPQN58.png"
    static let successKid = "https://imgur.com/ZUPQN58.png"
    static let lotsOfFaces = "https://imgur.com/96Hb18G.jpg"
}

typealias PhotoProcessingProgressClosure = (_ completionPercentage: CGFloat) -> Void
typealias BatchPhotoDownloadingCompletionClosure = (_ error: NSError?) -> Void

final class PhotoManager {
    private init() {}
    static let shared = PhotoManager()
    
    private var unsafePhotos: [Photo] = []
    private let concurrentPhotoQueue = DispatchQueue(
        label: "com.ray",
        attributes: .concurrent)
    
    var photos: [Photo] {
        var photosCopy: [Photo]!
        
        // 1
        concurrentPhotoQueue.sync {
            // 2
            photosCopy = self.unsafePhotos
        }
        return photosCopy
    }
    
    func addPhoto(_ photo: Photo) {
        concurrentPhotoQueue.async(flags: .barrier) { [weak self] in
            // 1
            guard let self = self else { return }
            
            // 2
            self.unsafePhotos.append(photo)
            
            // 3
            DispatchQueue.main.async { [weak self] in
                self?.postContentAddedNotification()
            }
        }
    }
    
    func downloadPhotos(withCompletion completion: BatchPhotoDownloadingCompletionClosure?) {
        var storedError: NSError?
        let downloadGroup = DispatchGroup()
        var addresses = [PhotoURLString.overlyAttachedGirlfriend,
                         PhotoURLString.successKid,
                         PhotoURLString.lotsOfFaces]
        
        // 1
        addresses += addresses + addresses
        
        // 2
        var blocks: [DispatchWorkItem] = []
        
        for index in 0..<addresses.count {
            downloadGroup.enter()
            
            // 3
            let block = DispatchWorkItem(flags: .inheritQoS) {
                let address = addresses[index]
                let url = URL(string: address)
                let photo = DownloadPhoto(url: url!) { _, error in
                    if error != nil {
                        storedError = error
                    }
                    downloadGroup.leave()
                }
                PhotoManager.shared.addPhoto(photo)
            }
            blocks.append(block)
            
            // 4
            DispatchQueue.main.async(execute: block)
        }
        
        // 5
        for block in blocks[3..<blocks.count] {
            
            // 6
            let cancel = Bool.random()
            if cancel {
                
                // 7
                block.cancel()
                
                // 8
                downloadGroup.leave()
            }
        }
        
        downloadGroup.notify(queue: DispatchQueue.main) {
            completion?(storedError)
        }
    }
    
    private func postContentAddedNotification() {
        NotificationCenter.default.post(name: PhotoManagerNotification.contentAdded, object: nil)
    }
}


//MARK: comments addPhoto
/*
 1. Вы отправляете операцию записи асинхронно с барьером. Когда он выполняется, это будет единственный элемент в вашей очереди.
 2. Вы добавляете объект в массив.
 3. Наконец, вы публикуете уведомление о том, что добавили фото. Вы должны опубликовать это уведомление в основном потоке, потому что оно будет работать с пользовательским интерфейсом. Таким образом, вы отправляете другую задачу асинхронно в основную очередь, чтобы вызвать уведомление.
 */

//MARK: comments var photos
/*
 1. Отправьте синхронно в concurrentPhotoQueue для выполнения чтения.
 2. Сохраните копию массива фотографий в photosCopy и верните ее.
 */

//MARK:
/*
 1. Вы расширяете массив адресов, чтобы вместить по три копии каждого изображения.
 2. Вы инициализируете массив блоков для хранения объектов блока отправки для последующего использования.
 3. Вы создаете новый DispatchWorkItem. Вы передаете параметр flags, чтобы указать, что блок должен наследовать свой класс качества обслуживания из очереди, в которую вы его отправляете. Затем вы определяете работу, которую нужно выполнить в закрытии.
 4. Вы отправляете блок асинхронно в основную очередь. В этом примере использование основной очереди упрощает отмену блоков выбора, поскольку это последовательная очередь. Код, который устанавливает блоки отправки, уже выполняется в основной очереди, поэтому вы можете быть уверены, что блоки загрузки будут выполнены в более позднее время.
 5. Вы пропускаете первые три блока загрузки, разрезая массив блоков.
 6. Здесь вы используете Bool.random () для случайного выбора между истинным и ложным. Это как подбрасывание монеты.
 7. Если случайное значение истинно, вы отменяете блокировку. Это может отменить только блоки, которые все еще находятся в очереди и еще не начали выполняться. Вы не можете отменить блок во время выполнения.
 8. Здесь не забудьте удалить отмененный блок из группы отправки.
 */


//MARK: comments downloadPhotos 2nd option
/*
 
 func downloadPhotos(withCompletion completion: BatchPhotoDownloadingCompletionClosure?) {
 // 1
 var storedError: NSError?
 let downloadGroup = DispatchGroup()
 for address in [PhotoURLString.overlyAttachedGirlfriend,
 PhotoURLString.successKid,
 PhotoURLString.lotsOfFaces] {
 let url = URL(string: address)
 downloadGroup.enter()
 let photo = DownloadPhoto(url: url!) { _, error in
 if error != nil {
 storedError = error
 }
 downloadGroup.leave()
 }
 PhotoManager.shared.addPhoto(photo)
 }
 
 // 2
 downloadGroup.notify(queue: DispatchQueue.main) {
 completion?(storedError)
 }
 }
 1. В этой новой реализации вам не нужно окружать метод асинхронным вызовом, поскольку вы не блокируете основной поток.
 2. notify (queue: work :) служит закрытием асинхронного завершения. Он запускается, когда в группе больше не осталось элементов. Вы также указываете, что хотите запланировать выполнение работы по завершению в основной очереди.
 */

//MARK: comments downloadPhotos 1st option
/*
 func downloadPhotos(withCompletion completion: BatchPhotoDownloadingCompletionClosure?) {
 // 1
 DispatchQueue.global(qos: .userInitiated).async {
 var storedError: NSError?
 
 // 2
 let downloadGroup = DispatchGroup()
 for address in [PhotoURLString.overlyAttachedGirlfriend,
 PhotoURLString.successKid,
 PhotoURLString.lotsOfFaces] {
 let url = URL(string: address)
 
 // 3
 downloadGroup.enter()
 let photo = DownloadPhoto(url: url!) { _, error in
 if error != nil {
 storedError = error
 }
 
 // 4
 downloadGroup.leave()
 }
 PhotoManager.shared.addPhoto(photo)
 }
 
 // 5
 downloadGroup.wait()
 
 // 6
 DispatchQueue.main.async {
 completion?(storedError)
 }
 }
 }
 1. Поскольку вы используете метод синхронного ожидания, который блокирует текущий поток, вы используете async, чтобы поместить весь метод в фоновую очередь, чтобы гарантировать, что вы не заблокируете основной поток.
 2. Создайте новую группу отправки.
 3. Вызовите enter (), чтобы вручную уведомить группу о запуске задачи. Вы должны сбалансировать количество вызовов enter () с количеством вызовов leave (), иначе ваше приложение выйдет из строя.
 4. Здесь вы уведомляете группу, что эта работа сделана.
 5. Вы вызываете wait (), чтобы заблокировать текущий поток, ожидая завершения задач. Это ждет вечно, и это нормально, потому что задача создания фотографий всегда завершается. Вы можете использовать wait (timeout :), чтобы указать тайм-аут и выйти из строя при ожидании по истечении указанного времени.
 6. На этом этапе вам гарантировано, что все задачи с изображениями либо завершены, либо истекло время ожидания. Затем вы делаете обратный вызов в основную очередь, чтобы запустить завершение закрытия.
 */
