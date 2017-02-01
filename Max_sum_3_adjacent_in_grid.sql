declare
type t is table of number ;
type t1 is table of t ;
t_tab t1 := t1(t(1,5,4) , t(19,7,29) , t(10,3,9) , t(5,38,2)) ;
a number ;
b number ;
a_var number ;
b_var number ;
t_sm t := t(0,1) ;
num_var number := 0;
t_sort t ;
procedure sort_array(arr in out nocopy t)
is
temp_num number := 1;
begin
  for i in arr.first .. arr.last loop
    for j in (i+1) .. arr.count loop
      if arr(i) < arr(j) then
         temp_num := arr(j) ;
         arr(j) := arr(i) ;
         arr(i) := temp_num ;
      end if ;
    end loop ;
  end loop ;
end ;
begin
for otr in t_tab.first .. t_tab.last loop      
  for inr in t_tab(otr).first .. t_tab(otr).last loop
    a := otr;
    b := inr;
    t_sort := t();
    t_sort.extend(1);
    t_sort(t_sort.last) := t_tab(a)(b);
        for j in t_sm.first .. t_sm.last  loop
          a_var := a + t_sm(j) ;
          for i in t_sm.first .. t_sm.last loop
            b_var := b + t_sm(i) ;
            if t_tab.exists(a_var) and t_tab(a_var).exists(b_var) then
              if to_char(otr||inr) <> to_char(a_var||b_var) then
                  t_sort.extend(1);
                  t_sort(t_sort.last) := t_tab(a_var)(b_var);
              end if ;
            end if;
          end loop ;
        end loop;
     if t_sort.count > 2 then
       sort_array(t_sort) ;
       for k in t_sort.first .. t_sort.last loop
        dbms_output.put(t_sort(k)||',');
       end loop;
       dbms_output.put_line('');
       if num_var < (t_sort(1) + t_sort(2) + t_sort(3)) then
         num_var := t_sort(1) + t_sort(2) + t_sort(3);
       end if ;
     end if;
  end loop; 
end loop ;
dbms_output.put_line(num_var) ;
end;


