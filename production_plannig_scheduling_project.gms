set i products /I01*I15, id01*id05/
    f product families /F01*F05/
    j processing units /J01*J03/
    n production periods /n1*n4/
    
    product_family(i,f) grouping products into families
    /(I01*I03).F01, (I04*I06).F02, (I07*I09).F03, (I10*I12).F04, (I13*I15).F05, id01.F01, id02.F02, id03.F03, id04.F04, id05.F05/
    
    family_unit(f,j) families that can be processed in unit j
    /#f.#j/

    product_unit(i,j) products that can be processed in unit j
    /#i.#j/
    
    unit_family(j,f) processing units that can process families
    /#j.#f/
         
    unit_product(j,i) processing units that can process product i
    /#j.#i/
;

display product_family, family_unit, product_unit, unit_family, unit_product;

alias (f, fp);
alias (n, np);

parameters
setup_time(i,j) /(I01*I15).(J01*J03) 0.5
                  (id01*id05).(J01*J03) 0.0/

setup_cost(i,j) /(I01*I15).(J01*J03) 50
                 (id01*id05).(J01*J03) 0.0/

operating_cost(i,j) /#i.#j 0.1/

production_rate_max(i,j) /#i.#j 10/

production_rate_min(i,j) /#i.#j 2/
* assuming 20% of max rate as min rate

processing_time_min(i,j,n) /#i.#j.#n 0.2/

processing_time_max(i,j,n) maximum processing time (see below)

inventory_cost(i,n) /#i.#n 1/

backlog_cost(i,n) /#i.#n 3/

;
display setup_time, setup_cost, production_rate_max;

parameter avail_production_time(j,n); avail_production_time(j,n)=24;

Table
changeover_time(f, fp, j)

    F01.J01 F02.J01 F03.J01 F04.J01 F05.J01 F01.J02 F02.J02 F03.J02 F04.J02 F05.J02 F01.J03 F02.J03 F03.J03 F04.J03 F05.J03
F01 0       3.0     3.0     5.0     1.5     0       3.0     3.0     5.0     1.5     0       3.0     3.0     5.0     1.5     
F02 5.3     0       3.0     3.0     2.0     5.3     0       3.0     3.0     2.0     5.3     0       3.0     3.0     2.0
F03 2.8     4       0       2.5     4.0     2.8     4       0       2.5     4.0     2.8     4       0       2.5     4.0
F04 2.4     4.0     3.0     0       3.0     2.4     4.0     3.0     0       3.0     2.4     4.0     3.0     0       3.0
F05 3.2     4.0     2.0     4.0     0       3.2     4.0     2.0     4.0     0       3.2     4.0     2.0     4.0     0
;

Table
changeover_cost(f, fp, j)

    F01.J01 F02.J01 F03.J01 F04.J01 F05.J01 F01.J02 F02.J02 F03.J02 F04.J02 F05.J02 F01.J03 F02.J03 F03.J03 F04.J03 F05.J03
F01 0       50      40      60      50      0       50      40      60      50      0       50      40      60      50
F02 40      0       50      80      90      0       0       50      80      90      0       0       50      80      90
F03 70      30      0       80      30      70      30      0       80      30      70      30      0       80      30 
F04 100     100     90      0       60      100     100     90      0       60      100     100     90      0       60
F05 30      50      50      70      0       30      50      50      70      0       30      50      50      70      0
;

Table
product_demand(i, n)

    N1  N2  N3  N4
I01 50  0   70  20
I02 0   80  10  50  
I03 30  50  20  30
I04 0   10  75  10
I05 70  90  10  20
I06 65  0   75  0
I07 40  50  0   30
I08 0   45  0   0
I09 55  0   45  15
I10 10  100 30  50
I11 40  15  20  30
I12 0   95  40  30
I13 80  0   40  30
I14 0   50  0   0
I15 0   0   0   60
id01 0  0   0   0
id02 0  0   0   0
id03 0  0   0   0
id04 0  0   0   0
id05 0  0   0   0
;

variables 
    B(i,n) backlog of product i at time n
    C(f,j,n) completion time for family f in unit j in period n
    P(i,n) total produced amount of product i in period n
    Q(i,j,n) produced amount of product i in unit j during period n
    S(i,n) inventory of product i at time n
    T(i,j,n) processing time for product i in unit j in period n
    TF(f,j,n) processing time for family f in unit j in period n
    U(j,n) time within period n consumed by a changeover operation that will be completed in next period on unit j
    Ubar(j,n) time within period n consumed by a changeover operation that started in previous period on unit j
;

Free variable z objective function;

positive variables
    Q(i,j,n), T(i,j,n), TF(f,j,n), C(f,j,n), B(i,n), S(i,n), P(i,n), Ubar(j,n), U(j,n);
    
binary variables
    WF(f,j,n) family f is assigned first to unit j in period n
    WL(f,j,n) family f is assigned last to unit j in period n
    X(f,fp,j,n) family f is processed exactly before fprime in period n in unit j
    Xbar(f,fp,j,n) family f in period n-1 is immediately followed from family fprime in unit j in period n
    Y(i,j,n) if product i is assigned to unit j in period n
    YF(f,j,n) family f is assigned to unit j in period n
;

Xbar.fx(f,fp,j,n)$(ord(n)=1) =0;

* calculating for idle units
processing_time_min(i,j,n)$(ord(i)>15) = 0;

processing_time_max(i,j,n)$(ord(i)<=15) = min(avail_production_time(j,n), sum(np, product_demand(i,np)/production_rate_min(i,j)));
processing_time_max(i,j,n)$(ord(i)>15) = avail_production_time(j,n);

*calculating for maintenance
set maintenance(j,n) /j01.n2,j02.n3, j03.n4/;

avail_production_time(j,n)$(maintenance(j,n)) = 0;
processing_time_min(i,j,n)$(maintenance(j,n)) = 0;
processing_time_max(i,j,n)$(maintenance(j,n)) = avail_production_time(j,n);
*YF.fx(f,j,n)$(maintenance(j,n)) = 0;

display avail_production_time, processing_time_min, processing_time_max;

equations
obj objective function.
eqn1 balancing product i produced in units j in period j.
eqn2 mass balance over a period n for a product i.
eqn3 inventory capacity constraints.
eqn4 constraint over a family as per the product in it.
eqn5 binary constraint over family forced to zero when no products are being produced in unit j.
eqn6 family sequencing if family f is assigned first and fp follows.
eqn7 family sequencing if family f is assigned last and has no successors.
eqn8 determining the correct number of immediate precedence.
eqn9 constraint to avoid sequence sub-cycles.
eqn10 family changeovers across adjacent periods from f to fp.
eqn11 constraint on family f processed last in period n-1 and fp is first in period n.
eqn12 changeover crossover constraint.
eqn13 unit production time.
eqn14_low lower bound on unit production.
eqn14_up upper bound on unit production.
eqn15_low lower bound on processing time.
eqn15_up upper bound on processing time.
eqn16 family and product processing times.
;

obj.. z=e= sum((i,n), inventory_cost(i,n)*S(i,n) + backlog_cost(i,n)*B(i,n)) +
           sum((i,j,n)$(ord(j)$unit_product(j,i)), setup_cost(i,j)*Y(i,j,n) + operating_cost(i,j)*Q(i,j,n)) +
           sum((f,fp,j,n)$(ord(fp)<>ord(f) and ord(j)$(unit_family(j,f) and unit_family(j,fp))), changeover_cost(f,fp,j)*(X(f,fp,j,n) + Xbar(f,fp,j,n)$(not maintenance(j,n) and not maintenance(j,n-1))));
           
eqn1(i,n) ..      P(i,n)=e= sum(j$(unit_product(j,i)), Q(i,j,n));  
eqn2(i,n)..       S(i,n) - B(i,n) =e= S(i,n-1) - B(i,n-1) + P(i,n) - product_demand(i,n);
eqn3(n)..         sum(i, S(i,n)) =l= 300;

eqn4(f,i,j,n)$(ord(i)$(product_family(i,f)) and ord(j)$(unit_family(j,f))).. YF(f,j,n) =g= Y(i,j,n);
eqn5(f,j,n)$(ord(j)$unit_family(j,f))..    YF(f,j,n) =l= sum(i$product_family(i,f), Y(i,j,n)); 

eqn6(f,j,n)$(ord(j)$unit_family(j,f))..    sum(fp$ (ord(fp) $ family_unit(f,j) and ord(fp)<>ord(f)), X(fp,f,j,n)) + WF(f,j,n) =e= YF(f,j,n);
eqn7(f,j,n)$(ord(j)$unit_family(j,f))..    sum(fp$ (ord(fp) $ family_unit(f,j) and ord(fp)<>ord(f)), X(f,fp,j,n)) + WL(f,j,n) =e= YF(f,j,n);
eqn8(j,n)..                                sum((f,fp)$ (ord(f)$family_unit(f,j) and ord(fp)$ family_unit(f,j) and ord(f)<> ord(fp)), X(f,fp,j,n)) + 1 =e= sum(f$ family_unit(f,j), YF(f,j,n));
eqn9(f,fp,j,n)$(ord(fp)<>ord(f) and ord(j)$(unit_family(j,f) and unit_family(j,fp))).. C(fp,j,n)=g=C(f,j,n) + TF(fp,j,n) + changeover_time(f,fp,j)*X(f,fp,j,n) - avail_production_time(j,n)*(1 - X(f,fp,j,n));

eqn10(f,j,n)$(ord(j)$unit_family(j,f) and ord(n)>1 and not maintenance(j,n) and not maintenance(j,n-1))..    WF(f,j,n) =e= sum(fp$ family_unit(f,j), Xbar(fp,f,j,n)$(not maintenance(j,n) and not maintenance(j,n-1))); 
eqn11(f,j,n)$(ord(j)$unit_family(j,f) and ord(n)>1 and not maintenance(j,n) and not maintenance(j,n-1))..    WL(f,j,n-1) =e= sum(fp$ family_unit(f,j), Xbar(f,fp,j,n)$(not maintenance(j,n) and not maintenance(j,n-1)));

eqn12(j,n)$(ord(n)>1 and not maintenance(j,n) and not maintenance(j,n-1))..  Ubar(j,n) + U(j,n-1) =e= sum((f,fp)$(ord(f)$(family_unit(f,j)) and ord(fp)<>ord(f) and ord(fp)$(family_unit(f,j))), changeover_time(f,fp,j)*Xbar(f,fp,j,n));

eqn13(j,n)..   Ubar(j,n) + U(j,n) + sum(f$family_unit(f,j), TF(f,j,n)) + sum((f,fp)$(ord(f)$(family_unit(f,j)) and ord(fp)<>ord(f) and ord(fp)$(family_unit(f,j))), changeover_time(f,fp,j)*X(f,fp,j,n)) =l= avail_production_time(j,n);

eqn14_low(i,j,n)$(ord(j)$unit_product(j,i))..  production_rate_min(i,j)*T(i,j,n) =l= Q(i,j,n);
eqn14_up(i,j,n)$(ord(j)$unit_product(j,i))..   production_rate_max(i,j)*T(i,j,n) =g= Q(i,j,n);
eqn15_low(i,j,n)$(ord(j)$unit_product(j,i))..  processing_time_min(i,j,n)*Y(i,j,n) =l= T(i,j,n);
eqn15_up(i,j,n)$(ord(j)$unit_product(j,i))..   processing_time_max(i,j,n)*Y(i,j,n) =g= T(i,j,n);
eqn16(f,j,n)$(ord(j)$unit_family(j,f))..       TF(f,j,n) =e= sum(i$ product_family(i,f), T(i,j,n) + setup_time(i,j)*Y(i,j,n));

option optcr =0;
Model plsrun /all/ ;
Solve plsrun using mip minimizing z ;

Display z.l, z.m, P.l, Q.l, plsrun.resUsd;
