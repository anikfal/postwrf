export equation=`cat totalequation.txt`
echo "Name of the polynomial" $equation "?"
read eqname
if [ -z "$eqname" ]
then
	touch eqname
	echo unknown_variable > eqname
else
	echo $eqname > eqname
fi
echo "Unit-scale of the polynomial" $equation "?"
read equnit
if [ -z "$equnit" ]
then
        touch equnit
        echo unknown_unit > equnit
else
        echo $equnit > equnit
fi
