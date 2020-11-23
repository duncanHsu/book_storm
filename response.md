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

  `/api/store/open/datetime`
+ List all book stores that are open on a day of the week, at a certain time

  `/api/store/open/dayOfWeek`
+ List all book stores that are open for more or less than x hours per day or week

  `/api/store/open/hours`
+ List all books that are within a price range, sorted by price or alphabetically

  `/api/book/priceRange`
+ List all book stores that have more or less than x number of books

  `/api/store/numberOfBooks`
+ List all book stores that have more or less than x number of books within a price range

  `/api/store/numberOfBooksWithinPriceRange`
+ Search for book stores or books by name, ranked by relevance to search term

  `/api/store/books/search`
+ The top x users by total transaction amount within a date range

  `/api/user/top/totalNumberDollarOfTransactions`
+ The total number and dollar value of transactions that happened within a date range

  `/api/user/transaction/total`
+ Edit book store name, book name, book price and user name

  `/api/user/edit/store`
  `/api/user/edit/book`
  `/api/user/edit/user`
+ The most popular book stores by transaction volume, either by number of transactions or transaction dollar value

  `/api/store/popular`
+ Total number of users who made transactions above or below $v within a date range

  `/api/user/transaction/numberOfUsers`
+ Process a user purchasing a book from a book store, handling all relevant data changes in an atomic transaction

## Import Data Commands (required)
  ```shell
  sequelize db:seed:all
  ```

## Demo Site Url (optional)
  demo ready on [AWS](http://18.163.129.189:3001/)
