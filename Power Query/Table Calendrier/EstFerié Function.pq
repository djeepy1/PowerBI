section Calendar;

shared EstFerié = (date) => 
let
	GetEasterDay = (annee) => 
	let
		/*annee = 2015,*/
		g = Number.Mod(annee,19),
		c = Number.IntegerDivide(annee,100),
		c4 = Number.IntegerDivide(c,4),
		e=Number.IntegerDivide((8*c+13),25),
		h=Number.Mod((19*g+ c-c4-e+15),30),
		h2 = if (h=29) then 28 else if (h=28 and g>10) then h-1 else h,
		k=Number.IntegerDivide(h2,28),
		p=Number.IntegerDivide(29,(h2+1)),
	q=Number.IntegerDivide((21-g),11),
		i=(k*p*q-1)*k+h2,
		b=Number.IntegerDivide(annee,4)+annee,
		j1=b+i+2+c4-c,
		j2=Number.Mod(j1,7),
		r=28+i-j2,
		jourDePaquesSTR="01/03/"&Text.From(annee),
		jourDePaquesDate = Date.FromText(jourDePaquesSTR),
		jourDePaque=Date.AddDays(jourDePaquesDate, r-1)
	in
		jourDePaque,
	annee = Date.Year(date),
	jour = Date.Day(date),
	mois = Date.Month(date),
	paques = GetEasterDay(annee),
	paquesLundi = Date.AddDays(paques, 1),
	ascension=Date.AddDays(paques, 39),
	pentecote=Date.AddDays(paques, 49),
	pentecoteLundi = Date.AddDays(pentecote, 1),
	estFerié = 
		if (mois=1 and jour=1) then true
		else if (mois=5 and jour=1) then true
		else if (mois=5 and jour=8) then true
		else if (mois=7 and jour=14) then true
		else if (mois=8 and jour=15) then true
		else if (mois=11 and jour=1) then true
		else if (mois=11 and jour=11) then true
		else if (mois=12 and jour=25) then true
		else if (date = paques) then true
		else if (date = paquesLundi) then true
		else if (date = ascension) then true
		else if (date = pentecote) then true
		else if (date = pentecoteLundi) then true
		else false
in 
	estFerié;