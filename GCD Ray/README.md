 ### Working with four classes
- PhotoCollectionViewController: The initial view controller. It displays the selected photos as thumbnails.
- PhotoDetailViewController: Displays a selected photo from PhotoCollectionViewController and adds googly eyes to the image.
- Photo: This protocol describes the properties of a photo. It provides an image, a thumbnail and their corresponding statuses. The project includes two classes which implement the protocol: DownloadPhoto, which instantiates a photo from an instance of URL, and AssetPhoto, which instantiates a photo from an instance of PHAsset.
- PhotoManager: This manages all the Photo objects.

![](images/GCD%20ray.gif)
