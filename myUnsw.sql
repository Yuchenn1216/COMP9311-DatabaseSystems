------------------------------------------------------
-- COMP9311 24T1 Project 1 
-- SQL and PL/pgSQL 
-- Template
-- Name: Yuchen Han
-- zID: z5587336
------------------------------------------------------

-- Q1:
create or replace view Q1(subject_code)
as
--... SQL statements, possibly using other views/functions defined by you ...
select s.code from subjects s, orgunits ou, orgunit_types ot
where s.offeredby = ou.id and ou.utype = ot.id
and ot.name = 'School' and ou.longname like '%Information%' and s.code like '____7___'
;

-- Q2:
create or replace view Q2(course_id)
as
-- ... SQL statements, possibly using other views/functions defined by you ...
select co.id from subjects s, classes cl, class_types ct, courses co
where cl.ctype = ct.id and cl.course = co.id and co.subject = s.id
and s.code like 'COMP%'
group by co.id
having count (distinct ct.name) = 2
and sum(case when ct.name in ('Lecture', 'Laboratory') then 1 else 0 end) = count (distinct cl.id)
;

-- Q3:
create or replace view Q3_1(unswid,student)
as
select p.unswid,s.id
from people p, students s
where p.id = s.id and CAST(unswid as text) LIKE '320%';

-- Find all courses that has at least two professors as staff 
create or replace view Q3_2(course)
as
select c.id,c.semester
from courses c, course_staff cs, staff s, people p
where c.id = cs.course and cs.staff = s.id and s.id = p.id and p.title ='Prof'
group by c.id
having count(p.title) >=2;

-- Find all student id who enrolled in at least 5 courses I year between 2008 ad 2012 
create or replace view Q3(unswid)
as
Select Q3_1.unswid
FROM students s, course_enrolments ce, Q3_2 c, semesters sem, Q3_1
where s.id = ce.student and ce.course=c.course and sem.id=c.semester and Q3_1.student=s.id and sem.year>=2008 and sem.year<=2012
group by s.id,Q3_1.unswid
having count(ce.course)>=5;

-- Q4:
create or replace view Q4_1(course_id, avg_mark)
as
select c.id, ROUND(avg(ce.mark):: numeric,2)
from students s, course_enrolments ce, courses c
where s.id=ce.student and ce.course = c.id 
and grade IN ('DN', 'HD')
group by c.id
order by c.id asc
;


create or replace view Q4_2(course_id,orgunit_id,semester,year, avg_mark)
as
select c.id, ogu.id, c.semester,sem.year, ROUND(avg(ce.mark):: numeric,2)
from students s, course_enrolments ce, courses c, subjects sub, orgunits ogu, orgunit_types ogut, semesters sem
where s.id=ce.student and ce.course = c.id and c.subject = sub.id and sub.offeredby = ogu.id and ogu.utype = ogut.id and c.semester = sem.id
and grade IN ('DN', 'HD')
and ogut.name = 'Faculty'
and sem.year = 2012
group by (c.id, ogu.id,ogut.name, c.semester,sem.year)
order by c.id asc
;


create or replace view Q4_3(course_id)
as
with RankedValues as (
    select Q4_2.course_id, Q4_2.orgunit_id, Q4_2.semester, Q4_2.avg_mark,
           rank() over (partition by Q4_2.orgunit_id, Q4_2.semester order by Q4_2.avg_mark desc) as rank
    FROM Q4_2
)
select course_id
from RankedValues
where rank  = 1
;

create or replace view Q4(course_id, avg_mark)
as
select Q4_1.course_id, Q4_1.avg_mark
from Q4_1, Q4_3
where Q4_1.course_id = Q4_3.course_id
order by Q4_1.course_id asc;
;



-- Q5:
create or replace view Q5_1(course,semester)
as
select Q3_2.course, Q3_2.semester 
from Q3_2, course_enrolments ce, semesters sem
where Q3_2.course  = ce.course and sem.id= Q3_2.semester 
and sem.year >= 2005 and sem.year <= 2015
group by (Q3_2.course,Q3_2.semester) 
having count(student)>500
;

create or replace view Q5(course_id, staff_name)
as
select Q5_1.course, STRING_AGG(CAST(p.given AS text), '; ') AS profname
from Q5_1, course_staff cs, staff s, people p,semesters sem
where Q5_1.course = cs.course and cs.staff = s.id and s.id = p.id and sem.id = Q5_1.semester
and sem.year >= 2005 and sem.year <= 2015
and p.title ='Prof'
group by Q5_1.course
order by profname;

-- Q6:

create or replace view Q6_1(room_id, num_of_classes) 
as
select r.id, count(cl.id) as num_of_rooms 
from classes cl, rooms r, semesters sem, courses c
where sem.id = c.semester and c.id = cl.course  AND cl.room = r.id
and sem.year =2012
group by r.id
order by num_of_rooms DESC
;

-- find the the ID of room(s) that were used most frequently by different classes in the year 2012
create or replace view Q6_2(room_id) 
as
select Q6_1.room_id
from Q6_1
where Q6_1.num_of_classes =  (
	select max(num_of_classes) from Q6_1)
;

-- the most frequent room, along with the subjets and number of subjects occupied in this room 
create or replace view Q6_3(room_id,subject,count_subject) 
as
select Q6_2.room_id, co.subject, count(co.subject)
from Q6_2, classes c, courses co
where Q6_2.room_id = c.room and c.course = co.id
group by co.id, Q6_2.room_id
order by count(co.subject) DESC;

-- the most frequen room, along with the most frequent subjects 
create or replace view Q6(room_id,subject_code) 
as 
select Q6_3.room_id, sub.code
from Q6_3, subjects sub
where Q6_3.count_subject = (
	select max(count_subject) from Q6_3)
and sub.id = Q6_3.subject;
;

-- Q7:
create or replace view Q7_1(student_id,org_id,program_id) 
as 
select p.unswid,ou.id,pro.id
from students s,people p, program_enrolments pe,course_enrolments ce,programs pro,courses c,semesters sem, orgunits ou,subjects sub
where p.id = s.id and ce.student=s.id and ce.course = c.id and c.semester = sem.id
and pe.student = s.id and c.semester = pe.semester and pro.id = pe.program and ou.id = pro.offeredby and sub.id = c.subject
and ce.mark >= 50
group by p.unswid,pro.id,ou.id
having (max(sem.ending) - min(sem.starting)) <= 1000 and sum(sub.uoc)>= pro.uoc
;


create or replace view Q7_2(student_id,org_id) 
as 
select Q7_1.student_id,Q7_1.org_id
from Q7_1, people p, students s, program_enrolments pe,semesters sem 
where Q7_1.student_id = p.unswid and Q7_1.program_id = pe.program and s.id = p.id and pe.student = p.id and pe.semester = sem.id
group by Q7_1.student_id, Q7_1.org_id
having count(distinct Q7_1.program_id)>=2
and (max(sem.ending)-min(sem.starting))<=1000
;


create or replace view Q7(student_id, program_id) 
as
select Q7_2.student_id, Q7_1.program_id
from Q7_2,Q7_1
where Q7_2.student_id =Q7_1.student_id and Q7_2.org_id = Q7_1.org_id
;

-- Q8:
create or replace view Q8_1(staff_id, org_id, role_number) 
as
select s.id,a.orgunit,count(sr.id)
from people p, staff s, affiliations a, staff_roles sr
where p.id = s.id and s.id = a.staff and a.role = sr.id
group by (s.id,a.orgunit)
order by (s.id,count(sr.id)) desc
;

-- sum the roles number for each staff among all orgs
create or replace view Q8_2(staff_id, count_roles) 
as
select staff_id,sum(role_number)
from Q8_1
group by staff_id
having max(role_number)>=3;


create or replace view Q8_3(staff_id, hdn_rate) 
as
select cs.staff,  ROUND(
        SUM(CASE WHEN ce.mark >= 75 THEN 1 ELSE 0 END) / NULLIF(COUNT(ce.mark), 0)::numeric,2)
from staff_roles sr,course_staff cs,courses c, semesters sem, course_enrolments ce
where sr.id=cs.role and cs.course= c.id and c.semester = sem.id and  c.id = ce.course
and sr.name = 'Course Convenor'
and sem.year = 2012
group by cs.staff
;

create or replace view Q8(staff_id, sum_roles, hdn_rate) 
as 
select distinct p.unswid,Q8_2.count_roles, Q8_3.hdn_rate
from Q8_2,Q8_3,people p
where Q8_2.staff_id = Q8_3.staff_id and Q8_3.staff_id = p.id 
order by Q8_3.hdn_rate desc 
limit 21
;

create or replace view Q8(staff_id, sum_roles, hdn_rate) 
as
with ranking as (
    select p.unswid as staff_id,Q8_2.count_roles as sum_roles, Q8_3.hdn_rate as hdn_rate,
	rank() over (order by Q8_3.hdn_rate desc) as rank
    from Q8_2,Q8_3,people p
    where Q8_2.staff_id = Q8_3.staff_id and  Q8_3.staff_id = p.id
)
select staff_id,sum_roles,hdn_rate
from ranking
where rank <= 20
order by hdn_rate desc, sum_roles desc;


-- Q9
create or replace function 
	Q9(unswid integer)  returns setof text
as $$
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;


-- Q10
create or replace function 
	Q10(unswid integer) returns setof text
as $$
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;

