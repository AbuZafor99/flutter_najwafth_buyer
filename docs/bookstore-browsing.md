# Public bookstore browsing

## API mapping and deployment

Deploy the backend change before releasing this Flutter build. The existing
production backend will otherwise return 404 for the new directory route; the
app shows an error and Retry while leaving the other home sections available.
No database migration or seed data is needed.

All paths below are relative to the configured `/api/v1` base URL.

| API | Frontend use | Access |
| --- | --- | --- |
| **New** `GET /shop/public?page=1&limit=12` | `BookstoreRepository`; home carousel requests six stores, All Bookstores loads subsequent pages | Public; Flutter explicitly strips Authorization |
| Existing `GET /books?shopId=<seller-user-id>&page=1&limit=20` | `BookRepository.getBooks`; bookstore books page | Public; Flutter explicitly strips Authorization for this view |
| Existing `GET /books/:id` | Existing book details and purchase flow | Public |
| Existing `GET /books` | Existing home catalog, popular/all books previews, search | Public |
| Existing `GET /category/tree/all`, `GET /category`, `GET /books?category=<id>` | Existing category integration | Public |

Directory response:

```json
{
  "success": true,
  "message": "Bookstores retrieved successfully",
  "data": {
    "shops": [{
      "ownerId": "111111111111111111111111",
      "shopId": "222222222222222222222222",
      "name": "Example bookstore",
      "description": "Store description",
      "address": "Public storefront address",
      "banner": [{"url": "https://example.com/banner.jpg"}]
    }],
    "pagination": {"page": 1, "limit": 12, "total": 1, "totalPages": 1}
  }
}
```

The IDs/content above illustrate the contract; the UI uses only API data.
Pagination requires a positive integer page and a limit from 1 to 50 (defaults:
1 and 12). Invalid values return 400 through the existing error middleware.
Empty results return 200 with `shops: []`; unexpected failures use the existing
backend error response. The existing books response remains
`data: { books: [...], meta: { page, limit, total, totalPage } }`.

`Book.shopId` references **User**, not Shop. The public response's `ownerId` is
therefore used for every bookstore book request, including subsequent pages.
`Shop.products` is not used because book uploads do not maintain that array.

The directory follows the existing admin directory's seller-based membership,
excluding soft-deleted sellers. It does not require `shopStatus: verified`:
existing shops default to `not verified`. Sellers without a Shop record use
their existing public name/username with no address or banner. Only the Shop's
storefront address is exposed; personal User addresses, contacts, certificates,
tokens, and order counts are excluded. Existing protected shop APIs are unchanged.

## Screens and behavior

- Existing Home: header/search → real bookstore carousel → categories → popular
  books → all-books preview. A book-feed failure does not hide the bookstore
  section. Categories retain their existing guest/authenticated navigation.
- All Bookstores (`/bookstores`): paginated directory with loading, empty,
  failure/retry, load-more, and pull-to-refresh states.
- Store books (`/bookstores/<ownerId>`): storefront information and a paginated,
  server-filtered book grid. Uses existing `BookCardMini`, book details routes,
  and guest purchase prompts. Back navigation retains the directory state.
- A failed next-page request retains loaded items and retries that same page.
- Portrait cover areas are taller, with `BoxFit.contain` for assets and network
  images. Existing metadata, add-to-cart actions, and image fallbacks remain.
  Grid heights account for screen width and text scale.

No bookstore ratings/favorites exist in the backend, so those reference-image
elements are omitted. Missing banners use a storefront icon; no mock stores or
books are injected. Existing home popularity/search behavior is retained; this
change does not introduce a new popularity ranking or global store search.

## Changed files

Frontend paths relative to `lib/`:

- `features/home/domain/bookstore.dart`
- `features/home/data/bookstore_repository.dart`, `book_repository.dart`
- `features/home/application/bookstore_provider.dart`
- `features/home/presentation/pages/bookstores_page.dart`, `bookstore_books_page.dart`
- `features/home/presentation/pages/home_page.dart`, `books_grid_page.dart`,
  `public_category_books_page.dart`, `featured_page.dart`
- `features/home/presentation/widgets/bookstore_card.dart`, `bookstore_carousel.dart`,
  `paginated_catalog.dart`, `home_tab.dart`, `book_card_mini.dart`,
  `store_widgets.dart`, `section_title.dart`
- `core/localization/app_localizations.dart` (English/French labels)

Backend: `controller/publicShop.controller.js`, `route/shop.route.js`,
`test/publicShops.test.js`. No schema or existing API contract changed.

## Verification

```sh
# Flutter
flutter analyze --no-pub
flutter test --no-pub test/bookstores_test.dart test/guest_browsing_test.dart test/public_category_test.dart

# Backend
node --test
```

Automated checks cover public headers with a stored token, owner-ID filtering,
pagination/retries, route/back navigation, guest purchase interception, empty
states, and portrait card layout at 320/800 logical pixels with enlarged text.
Backend tests cover public route placement, field privacy, active-seller filtering,
pagination validation, and the existing book query's owner filter.

Tests stub API/database responses; production data and real-device appearance
still need checking after backend deployment.
