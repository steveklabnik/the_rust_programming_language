all: _book
	
_book: SUMMARY.md README.md src
	rustbook build
