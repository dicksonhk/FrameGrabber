import PhotoAlbums
import UIKit

protocol AlbumsViewControllerDelegate: class {
    func controller(_ controller: AlbumsViewController, didSelectAlbum album: AnyAlbum)
}

class AlbumsViewController: UICollectionViewController {
    
    weak var delegate: AlbumsViewControllerDelegate?

    var albumsDataSource: AlbumsDataSource? = .default() {
        didSet { configureDataSource() }
    }

    private var collectionViewDataSource: AlbumsCollectionViewDataSource?
    private lazy var albumCountFormatter = NumberFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        configureDataSource()
    }

    @IBAction private func done() {
        presentingViewController?.dismiss(animated: true)
    }

    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let album = collectionViewDataSource?.album(at: indexPath) {
            delegate?.controller(self, didSelectAlbum: album)
        }
        
        done()
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? AlbumCell else { return }
        cell.imageRequest = nil
    }

    // MARK: - Private

    private func configureViews() {
        clearsSelectionOnViewWillAppear = true
        collectionView?.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactive

        collectionView?.collectionViewLayout = AlbumsLayout { [weak self] newItemSize in
            self?.collectionViewDataSource?.imageOptions.size = newItemSize.scaledToScreen
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(done))

        configureSearch()
    }

    private func configureSearch() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func configureDataSource() {
        guard isViewLoaded else { return }

        guard let dataSource = albumsDataSource else {
            collectionViewDataSource = nil
            collectionView.dataSource = nil
            return
        }

        collectionViewDataSource = AlbumsCollectionViewDataSource(collectionView: collectionView, albumsDataSource: dataSource, sectionHeaderProvider: { [unowned self] _, _, indexPath  in
            self.sectionHeader(at: indexPath)
        }, cellProvider: { [unowned self] _, indexPath, album in
            self.cell(for: album, at: indexPath)
        })

        collectionView?.dataSource = collectionViewDataSource
    }

    private func cell(for album: AnyAlbum, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = AlbumsSection(indexPath.section),
            let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: section.cellIdentifier, for: indexPath) as? AlbumCell else { fatalError("Wrong cell identifier or type or unknown section.") }

        configure(cell: cell, for: album, section: section)
        return cell
    }

    private func configure(cell: AlbumCell, for album: AnyAlbum, section: AlbumsSection) {
        cell.identifier = album.id
        cell.titleLabel.text = album.title
        cell.detailLabel.text = albumCountFormatter.string(from: album.count as NSNumber)
        cell.imageView.image = album.icon

        switch section {
        case .smartAlbum:
            cell.imageView.tintColor = .accent
        case .userAlbum:
            loadThumbnail(for: cell, album: album)
        }

        cell.isAccessibilityElement = true
        cell.accessibilityLabel = album.title
    }

    private func loadThumbnail(for cell: AlbumCell, album: AnyAlbum) {
        let albumId = album.id
        cell.identifier = albumId

        cell.imageRequest = collectionViewDataSource?.thumbnail(for: album) { image, _ in
            let isCellRecycled = cell.identifier != albumId
            guard !isCellRecycled, let image = image else { return }

            cell.imageView.contentMode = .scaleAspectFill
            cell.imageView.image = image
        }
    }

    private func sectionHeader(at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView?.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: AlbumsHeader.className, for: indexPath) as? AlbumsHeader,
            let section = collectionViewDataSource?.section(at: indexPath.section) else { fatalError("Wrong view identifier or type or no data source.") }

        header.titleLabel.text = section.title
        header.detailLabel.text = albumCountFormatter.string(from: section.albumCount as NSNumber)
        header.detailLabel.isHidden = section.isAvailable && section.isLoading
        header.activityIndicator.isHidden = !section.isAvailable || !section.isLoading

        return header
    }
}

// MARK: - Searching

extension AlbumsViewController: UISearchBarDelegate, UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        collectionViewDataSource?.searchTerm = searchController.searchBar.text
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        stopSearchingWhenSearchBarEmpty(searchBar)
    }

    private func stopSearchingWhenSearchBarEmpty(_ searchBar: UISearchBar) {
        guard searchBar.text?.trimmedOrNil == nil else { return }

        searchBar.text = nil
        
        // Setting `isActive` directly tends to dismiss the entire albums view controller.
        DispatchQueue.main.async {
            guard let searchController = self.navigationItem.searchController,
                  searchController.isActive else { return }
            
            searchController.isActive = false
        }
    }
}

// MARK: - Utilities

private extension AlbumsSection {
    var cellIdentifier: String {
        switch self {
        case .smartAlbum: return "SmartAlbumCell"
        case .userAlbum: return "UserAlbumCell"
        }
    }
}
