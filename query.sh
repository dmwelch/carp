#!/bin/bash
LOGIC=""  # Clear the logic 
read LOGIC
case $LOGIC in
        'Y' | 'y')  LOGIC=0 ;;
        'N' | 'n')  LOGIC=1 ;;
        'Q' | 'q')  . quit.sh ;;
        *        )  echo 'Invalid input.  Please enter "y" or "n"'
                    . query.sh ;;
esac