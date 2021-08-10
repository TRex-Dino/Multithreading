# Multithreading
## Use GCD Concepts
 ### Working with four classes
- PhotoCollectionViewController: The initial view controller. It displays the selected photos as thumbnails.
- PhotoDetailViewController: Displays a selected photo from PhotoCollectionViewController and adds googly eyes to the image.
- Photo: This protocol describes the properties of a photo. It provides an image, a thumbnail and their corresponding statuses. The project includes two classes which implement the protocol: DownloadPhoto, which instantiates a photo from an instance of URL, and AssetPhoto, which instantiates a photo from an instance of PHAsset.
- PhotoManager: This manages all the Photo objects.

### Quick guide of how and when to use the various queues with async
- Main Queue: This is a common choice to update the UI after completing work in a task on a concurrent queue. To do this, you code one closure inside another. Targeting the main queue and calling async guarantees that this new task will execute sometime after the current method finishes.
- Global Queue: This is a common choice to perform non-UI work in the background.
- Custom Serial Queue: A good choice when you want to perform background work serially and track it. This eliminates resource contention and race conditions since you know only one task at a time is executing. Note that if you need the data from a method, you must declare another closure to retrieve it or consider using sync.
