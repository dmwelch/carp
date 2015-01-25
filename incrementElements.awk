#!/bin/awk -f
# incrementElements.awk is a program that adds one to each node of an element for conversion from .vrml format to .dat or .mat format
BEGIN{
    i=0
}

$1 ~ /[0-9]/ {
    tab1[i]=$1+1
    }

$1 !~ /[0-9]/ {
    tab1[i]=$1
    }

$2 ~ /[0-9]/ {
    tab2[i]=$2+1
    }

$2 !~ /[0-9]/ {
    tab2[i]=$2
    }

$3 ~ /[0-9]/ {
    tab3[i]=$3+1
    }

$3 !~ /[0-9]/ {
    tab3[i]=$3
    }

    {i++ }
END{
    for(j=0;j<i+1;j++)

    print tab1[j], tab2[j], tab3[j] >FILENAME
    }