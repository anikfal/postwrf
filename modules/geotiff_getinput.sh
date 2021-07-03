export equation=`cat totalequation.txt`
echo "Name of the polynomial" $equation "?"
read eqname
if [ -z "$eqname" ]
then
	touch eqname
	echo polynomial > eqname
else
	echo $eqname > eqname
fi
echo "Unit-scale of the polynomial" $equation "?"
read equnit
if [ -z "$equnit" ]
then
        touch equnit
        echo no_unit > equnit
else
        echo $equnit > equnit
fi
