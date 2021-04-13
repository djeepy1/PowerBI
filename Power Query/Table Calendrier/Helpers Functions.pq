section Calendar;

shared GetFiscalMonth = (refdate as date) => 
    let
        //refdate  = #date(2019,1,1),
        refmonth = Date.Month(refdate),
        refmonthfiscal = if refmonth < 7 then refmonth + 6 else refmonth-7
    in refmonthfiscal;

GetFiscalYear = (refdate as date) => 
    let
        currentFiscalMonth = #"GetFiscalMonth"(refdate),
        currentYear = Date.Year(refdate),
        currentFiscalYear = if currentFiscalMonth <= 6 then currentYear + 1 else currentYear
    in
        currentFiscalYear;

isInOffsetCurrentFiscal = (refdate as date, offsetMonth as number) =>
let
    currentdate = DateTime.Date(DateTime.LocalNow()),
    currentFiscalMonth = GetFiscalMonth(currentdate),
    refFiscalMonth = GetFiscalMonth(refdate),
    isInOffset = if refFiscalMonth <= currentFiscalMonth + offsetMonth then true else false
in
    isInOffset;

isInOffsetMonth = (refdate as date, offsetMonthMin as number, offsetMonthMax as number) =>
    let
        currentdate = DateTime.Date(DateTime.LocalNow()),
        currentdateMonth = Date.Month(currentdate),
        currentdateYear = Date.Year(currentdate),
        refdateMonth = Date.Month(refdate),
        refdateYear = Date.Year(refdate),
        yearoffset = refdateYear - currentdateYear,
        monthoffset = refdateMonth - currentdateMonth,
        realoffsetMonth = yearoffset*12 + monthoffset,
        isinoffset = if realoffsetMonth >= offsetMonthMin and realoffsetMonth <= offsetMonthMax then true else false
    in
        isinoffset;

isInCurrentFiscalYear = (refdate as date) =>
    let
        refFiscalYear = GetFiscalYear(refdate),
        isInCurrentFiscalYear = refFiscalYear = GetFiscalYear(DateTime.Date(DateTime.LocalNow()))
    in
        isInCurrentFiscalYear;

GetFiscalYearStr = (refdate as date) => 
    "FY" & Text.End(Number.ToText(#"GetFiscalYear"(refdate)),2);

GetCurrentFiscalMonth = () =>
    #"GetFiscalMonth"(DateTime.Date(DateTime.LocalNow()));

GetCurrentFiscalYear = () =>
    #"GetFiscalYear"(DateTime.Date(DateTime.LocalNow()));

GetCurrentFiscalYearStr = () =>
    #"GetFiscalYearStr"(DateTime.Date(DateTime.LocalNow()));

isInCurrentFiscalMonth = (refdate as date) =>
    let
        currentdate = DateTime.Date(DateTime.LocalNow()),
        refFiscalYear = #"GetFiscalYear"(refdate),
        refFiscalMonth = #"GetFiscalMonth"(refdate),
        isInCurrentFiscalMonth = (refFiscalYear = #"GetFiscalYear"(currentdate)) and (refFiscalMonth = #"GetFiscalMonth"(currentdate))
    in
        isInCurrentFiscalMonth;