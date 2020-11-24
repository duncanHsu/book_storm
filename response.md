# BOOK STORM

[![npm](https://img.shields.io/badge/npm-v6.14.8-blue)](https://nodejs.org/zh-tw/download/) [![nodejs](https://img.shields.io/badge/node-v14.15.1-brightgreen)](https://nodejs.org/zh-tw/download/)

## API Document (required)
Import [this](https://raw.githubusercontent.com/duncanHsu/book_storm/master/BookStorm.postman_collection.json) json file to Postman

Add global environment to Postman
```
VARIABLE = BOOKSTORM_DOMAIN
VALUE = http://18.163.129.189:3001
```
## Task
+ List all book stores that are open at a certain datetime

| Method | URL |
| --- | --- |
| POST | /api/store/open/datetime |

| Param | Type | Description |
| --- | --- | --- |
| time | string | ISO format string |

+ List all book stores that are open on a day of the week, at a certain time

| Method | URL |
| --- | --- |
| POST | /api/store/open/dayOfWeek |

| Param | Type | Description |
| --- | --- | --- |
| time | string | ISO format string |

+ List all book stores that are open for more or less than x hours per day or week

| Method | URL |
| --- | --- |
| POST | /api/store/open/hours |

| Param | Type | Description |
| --- | --- | --- |
| dayOrWeek | string | day or week |
| moreOrLess | string | more or less |
| hours | number | bookstores open hours |

+ List all books that are within a price range, sorted by price or alphabetically

| Method | URL |
| --- | --- |
| POST | /api/book/priceRange |

| Param | Type | Description |
| --- | --- | --- |
| priceRange | number[] | price range |
| sortBy | string | price or alphabetically |

+ List all book stores that have more or less than x number of books

| Method | URL |
| --- | --- |
| POST | /api/store/numberOfBooks |

| Param | Type | Description |
| --- | --- | --- |
| moreOrLess | string | more or less |
| value | number | number of books |

+ List all book stores that have more or less than x number of books within a price range

| Method | URL |
| --- | --- |
| POST | /api/store/numberOfBooksWithinPriceRange |

| Param | Type | Description |
| --- | --- | --- |
| priceRange | number[] | price range |
| moreOrLess | string | more or less |
| value | number | number of books |

+ Search for book stores or books by name, ranked by relevance to search term

| Method | URL |
| --- | --- |
| POST | /api/store/books/search |

| Param | Type | Description |
| --- | --- | --- |
| target | string | store or book |
| keyword | string | search keyword |

+ The top x users by total transaction amount within a date range

| Method | URL |
| --- | --- |
| POST | /api/user/top/totalNumberDollarOfTransactions |

| Param | Type | Description |
| --- | --- | --- |
| top | number | number of users |
| dateRange | string[] | date range |
  ``
+ The total number and dollar value of transactions that happened within a date range

| Method | URL |
| --- | --- |
| POST | /api/user/transaction/total |

| Param | Type | Description |
| --- | --- | --- |
| dateRange | string[] | date range |

+ Edit book store name, book name, book price and user name

| Method | URL |
| --- | --- |
| POST | /api/user/edit/store |

| Param | Type | Description |
| --- | --- | --- |
| id | number | store id |
| new_name | string | new store name |
---
| Method | URL |
| --- | --- |
| POST | /api/user/edit/book |

| Param | Type | Description |
| --- | --- | --- |
| id | number | store id |
| new_name | string | new book name |
| new_price | number | new book price |
---
| Method | URL |
| --- | --- |
| POST | /api/user/edit/user |

| Param | Type | Description |
| --- | --- | --- |
| id | number | user id |
| new_name | string | new user name |

+ The most popular book stores by transaction volume, either by number of transactions or transaction dollar value

| Method | URL |
| --- | --- |
| POST | /api/store/popular |

| Param | Type | Description |
| --- | --- | --- |
| by | string | number or dollar |

+ Total number of users who made transactions above or below $v within a date range

| Method | URL |
| --- | --- |
| POST | /api/user/transaction/numberOfUsers |

| Param | Type | Description |
| --- | --- | --- |
| dateRange | string[] | date range |
| aboveOrBelow | string | below or below |
| value | number | number of users |

+ Process a user purchasing a book from a book store, handling all relevant data changes in an atomic transaction

## Import Data Commands (required)
  ```shell
  sequelize db:seed:all
  ```

## Demo Site Url (optional)
  demo ready on [AWS](http://18.163.129.189:3001/)
