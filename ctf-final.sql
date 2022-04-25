--
-- PostgreSQL database dump
--

-- Dumped from database version 13.6
-- Dumped by pg_dump version 13.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: check_submission(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_submission(submission text) RETURNS boolean
    LANGUAGE sql
    AS $$
SELECT (CASE WHEN COUNT(*) > 0 THEN true ELSE false END) FROM flags f WHERE submission ~* f.regexp
 $$;


ALTER FUNCTION public.check_submission(submission text) OWNER TO postgres;

--
-- Name: submit(text, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.submit(team_name text, submission text)
    LANGUAGE sql
    AS $$
INSERT INTO submissions (team_id, submission)  SELECT id, submission FROM teams WHERE name=team_name;
$$;


ALTER PROCEDURE public.submit(team_name text, submission text) OWNER TO postgres;

--
-- Name: submit2(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.submit2(team_id integer, submission text) RETURNS integer
    LANGUAGE sql
    AS $$
INSERT INTO submissions (team_id, submission) values (team_id, submission) RETURNING submissions.id;
$$;


ALTER FUNCTION public.submit2(team_id integer, submission text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attachments (
    name text,
    uri text,
    flag_id integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.attachments OWNER TO postgres;

--
-- Name: attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.attachments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: flags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.flags (
    id integer NOT NULL,
    visible boolean DEFAULT true,
    enabled boolean DEFAULT true,
    name text,
    description text DEFAULT ''::text,
    points integer,
    regexp text,
    solvable boolean DEFAULT true,
    parent integer
);


ALTER TABLE public.flags OWNER TO postgres;

--
-- Name: flags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.flags ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: ssh_keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ssh_keys (
    key text NOT NULL,
    id integer NOT NULL,
    team_id integer NOT NULL,
    key_type text NOT NULL
);


ALTER TABLE public.ssh_keys OWNER TO postgres;

--
-- Name: ssh_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.ssh_keys ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.ssh_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.submissions (
    id integer NOT NULL,
    team_id integer,
    submission text,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.submissions OWNER TO postgres;

--
-- Name: submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.submissions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: teams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teams (
    id integer NOT NULL,
    name text,
    enabled boolean,
    hash text
);


ALTER TABLE public.teams OWNER TO postgres;

--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.teams ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: v_flag_info; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_flag_info AS
SELECT
    NULL::text AS name,
    NULL::integer AS id,
    NULL::bigint AS solves,
    NULL::text[] AS teams;


ALTER TABLE public.v_flag_info OWNER TO postgres;

--
-- Name: v_solves; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.v_solves AS
 SELECT t.id AS team_id,
    f.id AS flag_id,
    array_agg(s.id ORDER BY s."timestamp") AS submissions
   FROM ((public.submissions s
     LEFT JOIN public.teams t ON ((s.team_id = t.id)))
     LEFT JOIN public.flags f ON ((s.submission ~* f.regexp)))
  WHERE (f.enabled AND f.solvable AND (f.regexp IS NOT NULL))
  GROUP BY t.id, f.id
  WITH NO DATA;


ALTER TABLE public.v_solves OWNER TO postgres;

--
-- Name: v_scoreboard; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_scoreboard AS
 SELECT row_number() OVER (ORDER BY (sum(f.points)) DESC) AS place,
    t.name,
    sum(f.points) AS score
   FROM ((public.v_solves vs
     LEFT JOIN public.teams t ON ((t.id = vs.team_id)))
     LEFT JOIN public.flags f ON ((vs.flag_id = f.id)))
  GROUP BY t.name
  ORDER BY (sum(f.points)) DESC;


ALTER TABLE public.v_scoreboard OWNER TO postgres;

--
-- Name: v_submission_count; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_submission_count AS
 SELECT submissions.team_id,
    count(*) AS attempts
   FROM public.submissions
  GROUP BY submissions.team_id;


ALTER TABLE public.v_submission_count OWNER TO postgres;

--
-- Name: v_submission_meta; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_submission_meta AS
 SELECT flags.name,
    flags.points,
    submissions.id AS submission_id,
    flags.id AS flag_id
   FROM (public.submissions
     LEFT JOIN public.flags ON ((submissions.submission ~* flags.regexp)));


ALTER TABLE public.v_submission_meta OWNER TO postgres;

--
-- Name: v_team_flags; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_team_flags AS
 SELECT v_solves.team_id,
    count(v_solves.flag_id) AS flag_count,
    array_agg(v_solves.flag_id) AS flags
   FROM public.v_solves
  GROUP BY v_solves.team_id;


ALTER TABLE public.v_team_flags OWNER TO postgres;

--
-- Name: v_team_info; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_team_info AS
 SELECT t.name,
    t.id,
    COALESCE(tf.flag_count, (0)::bigint) AS flag_count,
    tf.flags,
    COALESCE(sc.attempts, (0)::bigint) AS submission_attempts
   FROM ((public.teams t
     LEFT JOIN public.v_team_flags tf ON ((t.id = tf.team_id)))
     LEFT JOIN public.v_submission_count sc ON ((sc.team_id = t.id)));


ALTER TABLE public.v_team_info OWNER TO postgres;

--
-- Name: v_valid_submissions; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_valid_submissions AS
 SELECT COALESCE(to_char(s."timestamp", 'YYYY-MM-DD HH24:MI:SS'::text), '- -'::text) AS "time",
    t.name AS team_name,
    t.id AS team_id,
    f.name AS flag_name,
    s.id AS submission_id,
    f.id AS flag_id
   FROM (((public.submissions s
     LEFT JOIN public.v_solves vs ON ((ARRAY[s.id] <@ vs.submissions)))
     LEFT JOIN public.teams t ON ((t.id = vs.team_id)))
     LEFT JOIN public.flags f ON ((vs.flag_id = f.id)))
  WHERE (f.id IS NOT NULL);


ALTER TABLE public.v_valid_submissions OWNER TO postgres;

--
-- Data for Name: attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attachments (name, uri, flag_id, id) FROM stdin;
1944	http://files.secdsmctf.io/1944	2	1
url.bin	http://files.secdsmctf.io/url.bin	9	2
main.dis	http://files.secdsmctf.io/main.dis	12	3
main.dis	http://files.secdsmctf.io/main.dis	13	4
main.dis	http://files.secdsmctf.io/main.dis	14	5
secrets.dis	http://files.secdsmctf.io/secrets.dis	12	6
secrets.dis	http://files.secdsmctf.io/secrets.dis	13	7
secrets.dis	http://files.secdsmctf.io/secrets.dis	14	8
routines.dis	http://files.secdsmctf.io/routines.dis	12	9
routines.dis	http://files.secdsmctf.io/routines.dis	13	10
routines.dis	http://files.secdsmctf.io/routines.dis	14	11
secrets.m	http://files.secdsmctf.io/secrets.m	12	12
secrets.m	http://files.secdsmctf.io/secrets.m	13	13
secrets.m	http://files.secdsmctf.io/secrets.m	14	14
routines.m	http://files.secdsmctf.io/routines.m	12	15
routines.m	http://files.secdsmctf.io/routines.m	13	16
routines.m	http://files.secdsmctf.io/routines.m	14	17
fuego.dis	http://files.secdsmctf.io/fuego.dis	12	18
fuego.dis	http://files.secdsmctf.io/fuego.dis	13	19
fuego.dis	http://files.secdsmctf.io/fuego.dis	14	20
str.tar.gz	http://files.secdsmctf.io/str.tar.gz	15	21
str.tar.gz	http://files.secdsmctf.io/str.tar.gz	17	23
str.tar.gz	http://files.secdsmctf.io/str.tar.gz	18	24
str.tar.gz	http://files.secdsmctf.io/str.tar.gz	19	25
ret.tar.gz	http://files.secdsmctf.io/ret.tar.gz	16	27
ret.tar.gz	http://files.secdsmctf.io/ret.tar.gz	17	28
ret.tar.gz	http://files.secdsmctf.io/ret.tar.gz	18	29
ret.tar.gz	http://files.secdsmctf.io/ret.tar.gz	19	30
run.d	http://files.secdsmctf.io/run.d	23	32
reverse	http://files.secdsmctf.io/reverse	24	33
annoying	http://files.secdsmctf.io/annoying	25	36
mystery.png	http://files.secdsmctf.io/mystery.png	20	40
easy	http://files.secdsmctf.io/easy	62	37
flag.tar.gz	http://files.secdsmctf.io/flag.tar.gz	26	41
zip.tar.gz	http://files.secdsmctf.io/zip.tar.gz	22	31
\.


--
-- Data for Name: flags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.flags (id, visible, enabled, name, description, points, regexp, solvable, parent) FROM stdin;
5	f	t	Videocassette	Find a flag on a VHS tape!\n	150	^secdsm.being.green.is.sexy.as.f.$	t	\N
6	t	t	Tape1	Find a flag on a compact cassette!\n	200	^secdsm.show.me.your.love.$	t	\N
120	f	t	A test flag	Fake description	5	^secdsm.test.flag.here.$	t	\N
128	t	t	Floppy	Another floppy challenge	200	^secdsm.floppy.not.hard.$	t	\N
29	f	t	Filebox NFS	I'm sharing a few flags on my file server.\n\n3.15.30.73\n	150	^secdsm.be.a.warrior.$	t	28
30	f	t	Filebox HTML Comment	I'm sharing a few flags on my file server.\n\n3.15.30.73\n	50	^secdsm.nothing.will.burn.us.out.$	t	28
31	f	t	Filebox HTML Title	I'm sharing a few flags on my file server.\n\n3.15.30.73\n	150	^secdsm.de.la.capǎt.$	t	28
32	f	t	Filebox TFTP	I'm sharing a few flags on my file server.\n\n3.15.30.73\n	250	^secdsm.life.on.the.dark.side.$	t	28
33	f	t	Filebox FTP	I'm sharing a few flags on my file server.\n\n3.15.30.73\n	100	^secdsm.when.you.look.at.me.$	t	28
34	f	t	Filebox 9p	I'm sharing a few flags on my file server.\n\n3.15.30.73\n	200	^secdsm.take.a.shot.$	t	28
35	f	t	Filebox NFS Hidden	I'm sharing a few flags on my file server.\n\n3.15.30.73\n	25	^secdsm.tick.tock.take.you.dancing.$	t	28
36	f	t	Filebox Robots.txt	I'm sharing a few flags on my file server.\n\n3.15.30.73\n	50	^secdsm.parlez.de.moi.$	t	28
37	f	t	Filebox HTTP Header	I'm sharing a few flags on my file server.\n\n3.15.30.73\n	150	^secdsm.never.gives.a.damn.$	t	28
7	t	t	C64	Find a flag on a compact cassette!\n	250	^secdsm.the.heat.is.getting.higher.$	t	\N
8	f	t	Metadata	Find a flag on a compact cassette!\n	200	^secdsm.hi.baby.here.i.am.$	t	\N
9	t	t	Epic	How epic is your sax?\n	100	^secdsm.some.win.when.others.become.legends.$	t	\N
10	t	t	Free Points!	Get some free points with SecDSM{free_points}!\n	10	^secdsm.free.points.$	t	\N
11	f	t	More free points!	Get some free points with SecDSM{free_points}!\n	15	^secdsm.more.free.points.$	t	\N
12	t	t	Fuego		250	^secdsm.yeah.yeah.fire.$	t	\N
13	f	t	Fire		50	^secdsm.alternative.init.$	t	\N
14	f	t	Inferno		150	^secdsm.and.alternative.secrets.$	t	\N
17	f	t	Hidden	Reverse engineer the attached binary to find\nan exploit, and then try it against the online\ninstance!\n	25	^secdsm.sacando.un.pecho.fuera.al.puro.estilo.delacroix.$	t	\N
18	f	t	Hidden	Reverse engineer the attached binary to find\nan exploit, and then try it against the online\ninstance!\n	25	^secdsm.no.sé.por.qué.dan.tanto.miedo.nuestras.tetas.$	t	\N
19	f	t	Tryhard	Reverse engineer the attached binary to find\nan exploit, and then try it against the online\ninstance!\n	750	^secdsm.not.even.sure.that.was.possible.$	t	\N
20	t	t	Winner		200	^secdsm.are.you.the.winners.$	t	\N
21	f	t	Loser		25	^secdsm.vote.for.the.winners.$	t	\N
22	t	t	Zipper		250	^secdsm.i.cant.wait.to.know.$	t	\N
26	t	t	LVWhat?	Find the flag in the attached files.\n	200	^secdsm.heroes.of.our.time.$	t	\N
27	f	t	Hidden	Find the flag in the attached files.\n	50	^secdsm.still.in.love.$	t	\N
28	t	t	Filebox	I'm sharing a few flags on my file server.\n\n3.15.30.73\n	1125	DUMMYFLAG	f	\N
52	f	t	Grayscale 2	Figure out the right solution to submit and find some flags along the way.\n	25	^secdsm.bpg1.e2jwzzjf.$	t	50
53	f	t	Grayscale 3	Figure out the right solution to submit and find some flags along the way.\n	50	^secdsm.bpg3.y29uz3jh.$	t	50
54	f	t	Grayscale 4	Figure out the right solution to submit and find some flags along the way.\n	50	^secdsm.bpg4.dhvsyxrp.$	t	50
55	f	t	Grayscale 5	Figure out the right solution to submit and find some flags along the way.\n	75	^secdsm.bpg5.b25zx21l.$	t	50
56	f	t	Grayscale 6	Figure out the right solution to submit and find some flags along the way.\n	50	^secdsm.bpg6.dgffzmxh.$	t	50
57	f	t	Grayscale 7	Figure out the right solution to submit and find some flags along the way.\n	75	^secdsm.bpg7.z3nfyxjl.$	t	50
58	f	t	Grayscale 8	Figure out the right solution to submit and find some flags along the way.\n	50	^secdsm.bpg8.x3nvx2hv.$	t	50
59	f	t	Grayscale 9	Figure out the right solution to submit and find some flags along the way.\n	200	^secdsm.bpg9.df9yawdo.$	t	50
60	f	t	Grayscale 10	Figure out the right solution to submit and find some flags along the way.\n	150	^secdsm.bpg10.df9ub3d9.$	t	50
61	f	t	Grayscale BONUS	Figure out the right solution to submit and find some flags along the way.\n	250	^secdsm.bpg2.congratulations.meta.flags.are.so.hot.right.now.$	t	\N
51	f	t	Grayscale 0	Figure out the right solution to submit and find some flags along the way.\n	50	^secdsm.bpg0.u2vjrfnn.$	t	50
3	t	t	Videocassete 1	Find a flag on a VHS tape!\n	200	^secdsm.ride.your.bicycle.instead.of.a.car.$	t	\N
4	t	t	Videocassete 2	Find a flag on a VHS tape!\n	200	^secdsm.you.should.eat.your.salad.$	t	\N
2	t	t	1944	nc 3.145.53.138 4002	200	^secdsm.strangers.are.coming.$	t	\N
62	t	t	Easy	nc 3.145.53.138 4003	150	^secdsm.take.it.on.$	t	\N
23	t	t	Password	See if you can figure out the super secret password, then try it\nagainst the online version!\nnc 3.145.53.138 4001	150	^secdsm.just.like.a.hurricane.$	t	\N
24	t	t	Reverse	nc 3.145.53.138 4004	150	^secdsm.my.number.one.$	t	\N
25	t	t	Annoying	nc 3.145.53.138 4005	200	^secdsm.you.are.the.one.$	t	\N
38	t	t	Floppy ASK	Find a flag on a floppy.	50	^secdsm.you.put.them.together.$	t	\N
63	t	t	Badge 1	An easy badge flag. 115200 8N1	75	^secdsm.hope.you.used.putty.$	t	\N
65	t	t	Hack the badge.	?????	250	^secdsm.journeyman.badge.hacker.$	t	\N
66	t	t	Scavenger	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	1337	^secdsm.have.fun.$	f	\N
50	t	t	By the Power of Grayscale	Figure out the right solution to submit and find some flags along the way.\n  http://3.145.88.61:8080	775	DUMMYFLAG	f	\N
64	t	f	Badge 2	Ampy might help you here.	150	^secdsm.you.can.now.program.your.badge.$	t	\N
121	f	t	Wifi 1	In the air	50	^secdsm.fbi.van.13.$	t	\N
69	f	t	Scavenger -  WindowsL	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.lock.it.$	t	66
122	f	t	Wifi 2	Pretty Fly for a wifi	50	^secdsm.wutang.lan.$	t	\N
123	f	t	Wifi 3	Tell My Wifi I love her	50	^secdsm.burns.when.ip.$	t	\N
124	f	t	Wifi 4	Latency King	50	^secdsm.lord.of_the_ping.$	t	\N
125	f	t	Wifi 5	two if by sea	50	^secdsm.one.if.by.lan.$	t	\N
15	t	t	STR	Reverse engineer the attached binary to find\nan exploit, and then try it against the online\ninstance!\n\\n\\nnc 18.118.122.215 4001	100	^secdsm.larger.than.dreams.$	t	\N
16	t	t	RET	Reverse engineer the attached binary to find\nan exploit, and then try it against the online\ninstance!\n\\n\\nnc 18.118.122.215 4002	250	^secdsm.so.many.tears.$	t	\N
68	f	t	Scavenger -  Hub	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	30	^secdsm.collision.domains.ftw.$	t	66
67	f	t	Scavenger -  Unrack	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	150	^secdsm.better.go.catch.it.$	t	66
70	f	t	Scavenger -  Frontpage	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.dont.you.dare.$	t	66
71	f	t	Scavenger -  Phishing	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.dont.click.the.link.$	t	66
72	f	t	Scavenger -  Scammer	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.so.frusterating.$	t	66
73	f	t	Scavenger -  Retweet	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.twitter.verified.$	t	66
74	f	t	Scavenger -  Passphrase	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.dont.forget.it.$	t	66
75	f	t	Scavenger -  Transportation	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	100	^secdsm.burn.rubber.$	t	66
76	f	t	Scavenger -  2factor	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	50	^secdsm.practice.what.you.preach.$	t	66
77	f	t	Scavenger -  Cable	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.use.it.someday.$	t	66
78	f	t	Scavenger -  Meme	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	15	^secdsm.thanks.for.laughs.$	t	66
79	f	t	Scavenger -  Printer	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	15	^secdsm.smelly.plastic.$	t	66
80	f	t	Scavenger -  Sporty	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	50	^secdsm.rwd.is.best.$	t	66
81	f	t	Scavenger -  DDR1	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	75	^secdsm.to.the.trash.$	t	66
82	f	t	Scavenger -  Pool	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.hey.hold.the.door.$	t	66
83	f	t	Scavenger -  Ids	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	10	^secdsm.suri.is.goat.$	t	66
84	f	t	Scavenger -  Backpain	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.so.much.material.$	t	66
85	f	t	Scavenger -  Beverages	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.party.all.day.$	t	66
86	f	t	Scavenger -  Helloworld	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	50	^secdsm.echo.foobar.$	t	66
87	f	t	Scavenger -  Cracked	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	10	^secdsm.thanks.crackstation.$	t	66
88	f	t	Scavenger -  Collision1	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	50	^secdsm.easy.odds.here.$	t	66
89	f	t	Scavenger -  Collision2	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.what.are.the.odds.$	t	66
90	f	t	Scavenger -  Starke	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	15	^secdsm.maximum.grip.$	t	66
91	f	t	Scavenger -  Veteran	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	30	^secdsm.how.did.you.get.that.$	t	66
92	f	t	Scavenger -  Homeade	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	30	^secdsm.crafty.you.are.$	t	66
93	f	t	Scavenger -  Decode	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	50	^secdsm.uncommon.encoders.$	t	66
94	f	t	Scavenger -  Pin	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.knock.it.over.$	t	66
95	f	t	Scavenger -  Projector	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.idk.bm.wanted.this.$	t	66
96	f	t	Scavenger -  Parking	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.did.you.steal.it.$	t	66
97	f	t	Scavenger -  Tmps	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	30	^secdsm.deflated.$	t	66
98	f	t	Scavenger -  Pocsag	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	30	^secdsm.beep.beep.$	t	66
99	f	t	Scavenger -  Adsb	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	30	^secdsm.not.a.ufo.$	t	66
126	t	t	Floppy ???		250	^secdsm.crossed.your.mind.$	t	\N
101	f	t	Scavenger -  Pizza	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.best.in.us.$	t	66
102	f	t	Scavenger -  Adapter	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	25	^secdsm.complex.adapter.$	t	66
103	f	t	Scavenger -  Reverse	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	35	^secdsm.nick.is.so.cool.$	t	66
104	f	t	Scavenger -  Resistor	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	30	^secdsm.tbd.$	t	66
100	f	t	Scavenger -  Shots	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	10	^secdsm.the.impossible.$	t	66
106	t	t	Confluence root	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	200	^secdsm.a07be5de-daa8-4664-90b0-f95616faf67a.$	t	119
107	t	t	Gitlab root	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	200	^secdsm.00047e92-6a7e-44cf-8dee-a4ad8cc63531.$	t	119
108	t	t	Apache root	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	150	^secdsm.fc8c9896-7f1a-453f-bfca-48a9010a5bf8.$	t	119
109	t	t	Jenkins root	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	300	^secdsm.a54a42a6-e2bd-46ec-969c-ea8f5741dc62.$	t	119
110	f	t	Keycloak root	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	300	^secdsm.54b5d1d5-7ea7-4d7b-8ac3-ed542729c1b7.$	t	119
111	t	t	Mariadb db	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	200	^secdsm.8f6828da-2c8e-48f7-aae6-83f02ab7da3f.$	t	119
105	f	t	Scavenger -  Thicknet	Scavenger Hunt:\n\nChallenges will fall under 2 catagories. You will either prove you have completed a task or bring us an item.\n\nIf an item is brought to us we will return it when we are done admiring it. We will not keep anything so bring your best.\n\nAll flags are at the discretion of the judges.\n\nBrown Bottle Bribes (bribes will be accepted for flags)\n\n1: Unrack a running server\n2: Bring me a working hub.\n3: Find an unlocked device that you shouldn't have access to.\n4: Show me the most archaic website you know of. (Show me some CVEs related to it)\n5: Show me a real phishing site.\n6: Call a scammer.\n7: Get someone famous to retweet you. (tweet must contain #bsidesIA)\n8: Demonstrate your computer password uses more than 64 characters.\n9: Hack your own car.\n10: Demonstrate unconventional mfa usage.\n11: Bring me the most obscure cable in your cable junk box.\n12: Show me a tech meme that makes me laugh.\n13: Bring me something 3d printed.\n14: Let me drive your "cool" car through the parking lot. (Bonus if it's EV or modified)\n15: Bring me a stick of ddr1 memory.\n16: Take a picture of the pool on the roof.\n17: What is your favorite IDS engine. Be prepared to defend your reason. There is a wrong answer.\n18: Bring me your thickest cybersec book.\n19: Show me how you're smuggling beverages.\n20: Show me your most innefficient hello world.\n21: Crack this hash: 272040DC6223AB1D17CA1EE4BB9FFA15\n22: Show me an example of crc32 hash collision and prove it.\n23: Show me an example of md5 hash collision and prove it.\n24: What is Nick Starke's go to foot wear?\n25: Bring some veteran SecDSM swag.\n26: Make your own SecDSM swag.\n27: Decode this: F(/TsDIjs\n28: Bring me a bowling pin.\n29: Bring a slide projector.\n30: Bring me a parking meter.\n31: Decode TPMS.\n32: Decode POCSAG.\n33: Use ADS-B to track a plane.\n34: Get arden to drink and swallow a shot of alcohol.\n35: Bring me a slice of caseys pizza.\n36: Bring me the most complex adapter from ps2 to usb.\n37: What is the command ID in Nick Starke's presentation.\n	40	^secdsm.tbd.$	t	66
112	t	t	Postgres db	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	200	^secdsm.a2dffc04-2621-4e0d-8192-0e115ffb142d.$	t	119
113	f	t	Httpd default header	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	50	^secdsm.1bc3fdd0-dd5b-4c0e-b864-112ea10f403b.$	t	119
114	f	t	Httpd gitlab header	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	50	^secdsm.8162daa2-c1db-4322-8a17-ee3e41a85af4.$	t	119
115	f	t	Httpd sso header	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	50	^secdsm.9029a3c5-96c9-45cd-9b77-72df48a030f7.$	t	119
116	f	t	Httpd docs header	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	50	^secdsm.8f6828da-2c8e-48f7-aae6-83f02ab7da3f.$	t	119
117	f	t	Httpd jenkins header	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	50	^secdsm.bbac5998-3102-4080-af68-7a061832ef36.$	t	119
118	t	t	Drahosj GitLab	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	150	^secdsm.5b74eb06-1402-448f-90eb-2498102d95f3.$	t	119
119	t	t	Devoops	  ___               ___\n (o o)             (o o)\n(  V  ) Dev Oops! (  V  )\n--m-m---------------m-m--\n\nHack the Things, Find The Flags\n\n\nWelcome to Dev Oops!\n\nWe store all the docs on this website\n    http://docs.secdsmctf.io\n\n Do Things with Jenkins!\n    http://jenkins.secdsmctf.io\n\nCheck out the UnCTFd Platform and other repo from our main dev!\n   http://gitlab.secdsmctf.io/drahosj/\n\n    There are several repos here, lots of helpful scripts!	666	DUMMYFLAG	f	\N
127	t	t	Easy Tape	An easier tape challenge	200	^secdsm.tape.ftw.$	t	\N
129	t	t	Call The Phone	\nCall the phone\n\nThe phone is on the university network at 192.168.102.122.\nWeb interfaces are not in scope.\nReconfiguration of the phone is not in scope.\nDenial of service of the phone is not in scope.\nThe University network is not is scope. \nOnly calling the phone using SIP is in scope.\n\nHint: No system exploitation is required or allowed to complete this challenge.	150	^secdsm.make.it.ring.$	t	\N
130	t	t	Beg or Bribe	Bribe the judges	1	^secdsm.must.be.desperate.$	t	\N
\.


--
-- Data for Name: ssh_keys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ssh_keys (key, id, team_id, key_type) FROM stdin;
AAAAB3NzaC1yc2EAAAABIwAAAIEA3D5KjXV/kCbXi6zmh9YBTCpzZZ/PT0LAiwwu+gQxFNOeCaAFBvSycHb52/tSfqpX+tayJgsX726lmDndzjkEsDu9G1UjYlMnh/mzeBJ+hNn0vs+47r9uQH4ytRKNXoKvXrIyVORNJ2DnReAtbziP71TNm0iDNkq1x634vwDm9ZU	26	10	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAACAQC7zQbsD0B4cGFmANf8313USKomV+ob6J1/MQ2T89sytM/C7cVQObXWYnw/AzfveZst+CSeUc0MGXgw52dkm4gm4nC8TSVkSchNljkzLyAfw3x5IfxKyPeHDz+LnCEu5YIEoqrCl7g13WFvyg0Tu7qhX1U0YNLWiYxbn2cX+L/TsxWpYEpaWjjRPHUxobH0SC0V5HoADuJ6IDZPbKmUtli6eRVlgsiGwuJenmBVCLnHWKil7tMAt2YsQ5Zu5De63kOYU1pTF5C+iHe5ohR805w3wSC+aYvjd9Jy4UcdMYvwbgT4BHOA/kh59tNOKpa23SD7oOoY+003ZG6UZYx76oQfGoAK+Ad/5mktn8xZ4z25231q9NIN3q279nMNrDWzTeXwqzP6Ly3ON2q3yf6OtEsckCJSWwShs38O9ZgEygabatYuDlbssLkn4OtU5uVAIdSnhIqjNKA2MlgUXwwqZLCMTwJpEAM8K3EPvUvoY+vo+MZtADLVsVTx5Z04mNra6hAc+9SMKlGfJml8Ljkkf54jgS0Ii8Y5SDiQgC+3lqiE/o9FjFcuP+W3YPKv0BjjK6an5oJ0sLSq5EORO5fckjcDb/zdjSQbhpGmFSDjzR+aL6dP1vIBHoY/gtlG0Pibf3ryUopfkgj/zFvF3e4LLtJzwB7pkgTBOfiGS8d2CHNEwQ	27	16	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDJwGVhPZzW8/c4x+xJPXpzSVw8dCi+3Rwt3pFwe/u244Hp0zBKmJCjIzHqpwaKuavpcXojUm16o6+znfDaaZh3mO3ET7k8chEComJsLYsLWruHTQ07rI4xaCFDB2fWFF903xpSJRVtVPjsr1GPDVxx/34V8dPc5p+thF4sh7F/TWZ+7gHKLY2T50c2BkcQDQ3oKcWgzEuc8fqWAYFkZXJzGvqmoR9QGztU2RBs0Q+lxDc4nb4eUOuHK4KUIBGDdZzU9I67Ie/PBNjZCw/U81qG6KCTYumU0jNuh+AAKe0dsy/US6HU8Xzmz4tqTEA3d8JTv30qL6u6sXecz9a700T/C5dC8mnZ4q+CpGqA+1Kzt/eAk7HJVs+hblNZlkjGNYH1hW6UaWaBbtsC+8pkKq/kJOYKGXvJb0oupxE9liGDmIIsP7f4hV3lHv8NDNneXuE53iJrteZ4dq/GjZmxRKIIHgoScfy9kT8uE0I4MBMSRkIL4NxYp2Q7+u++9iC1TxU	28	16	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDivse+1K50W9pdrAF1l3EAKk4xWBRHPBewYrhnxt3uL9Y2ynglcpgZZ9nYjtGKYgQRu8V1j2rZxiwFWqkP+ZC0dGfs5IRN4CwnQvwNXoJ7r6WwcOU36YWGIN/J2EdIhek10LJmQkDHhYnYSkn9xzS64w0XpmHt4V+8bu3EvVeEHXS6iYMdyTFusFBS/GnoaMLT/slQaf+Huo1TL3snBnlI/SoLSKGjyO4+KJ2YgqmDkVISt6tzoaVW1Kjht/8V8jmNMjUDAKF/xxMVATf7s57jKneSTV1u6OneeSJsv7atkwR9mYop+jCCvrQf/mQPaLLBfn5So2vOHHZNQ9992RqbwDerdVjnEO1HZilpjHfoh5aRU9RMCNcxwb8Rw+bsGBYUpKsDCQDI21yIamHinV6qZtY0gCbMhDX8iUM54CtjpmKv5+cnnB6rbuDXfwOzgdsNW7FPXQo4pTvGI0Bj56rTFTAcJpS9RxSU/fdJCwfOsegGZWrQP96dUA2GPWC4ArM	29	1	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABAQDG1w/U8n9cw8spPW7gOWqxdMMoIAnz8VIlN0IV5NGITPsdlKaxyZQZ3v1RoQGkG7jVCCEuV0UFxRkSTvSSj+d9aHQh2YEKIVWtx7Ts1c6Gv7gsBhy6CoiV4b16Nq7enalaaPIGuuDHPx/hQ33Y7oJ8cRgqjunZxyBNVhaX0vy84RnsNhftisiOUgo5tdoFBkDykkdvjxvK9Bn4zXdoLmp+muaJjUJC0Dtasg+d4Q0UWdjlTHNamrYLt1JspyW1cPFXmbPqImiYCXrIvTyx0LHAoxrHBvRacxx8UcdCSfBE0psjHlvHAGokQns5g1//zzYCuMzfUuCXFZkQ1ehCnVkH	30	13	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQC2COlgdtEKMC+jCQ5iANGNWRoHfX+L2xwwJ4GrCkwi8mX3kIO+oNUayIPs1LTHSHL868X5iEu0JHbFpqQIILK1JD21RnPQiyjbydApq9zqRiyehdIN63oxfN4f3NW6CnPhRylKVx+WgRA8O6Nsunw7MSEUnIU6ixU/YdHETq2W0wHlxpjfdgmcY2dxHJKZYN57FCi6XeZkD6mzDJqvcB9gz0HPsKjQFxVgWVxk0u7qnk8n0oj+38K3k/iEDqqfLmDSU5/85hQIHFjGgUzpgJWfPxxvwH9wak9zj2U+AK0AbvGgYlQXgbn6Bj5qSKew643iA7T/To1rJnYyVTNnx4lwHimJXw+4d2XQWQhg5wKNI/op/2zUaLsAyOa6B3uDljilS5lY69rDEdORQ2oZTfOSXB+SYay5j4mQSVIFRmqB/TYC93uxO2HRNdJu1dgg/QOd5qCrJeP2Fd2FOm+v3+6x7e07cdvYpm16dJx4uHlqER2aUlX1/MRtEEcyNw3knNM	31	18	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDivse+1K50W9pdrAF1l3EAKk4xWBRHPBewYrhnxt3uL9Y2ynglcpgZZ9nYjtGKYgQRu8V1j2rZxiwFWqkP+ZC0dGfs5IRN4CwnQvwNXoJ7r6WwcOU36YWGIN/J2EdIhek10LJmQkDHhYnYSkn9xzS64w0XpmHt4V+8bu3EvVeEHXS6iYMdyTFusFBS/GnoaMLT/slQaf+Huo1TL3snBnlI/SoLSKGjyO4+KJ2YgqmDkVISt6tzoaVW1Kjht/8V8jmNMjUDAKF/xxMVATf7s57jKneSTV1u6OneeSJsv7atkwR9mYop+jCCvrQf/mQPaLLBfn5So2vOHHZNQ9992RqbwDerdVjnEO1HZilpjHfoh5aRU9RMCNcxwb8Rw+bsGBYUpKsDCQDI21yIamHinV6qZtY0gCbMhDX8iUM54CtjpmKv5+cnnB6rbuDXfwOzgdsNW7FPXQo4pTvGI0Bj56rTFTAcJpS9RxSU/fdJCwfOsegGZWrQP96dUA2GPWC4ArM	32	1	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABAQC93IDz35fRWogH7I5wqPOeERos1J3xvzFZG6oFTL0GKKNFk+8l3H1Edq8VOjsf8nA/260XL/pSOjdx/UicwWM+axgfzyozIcenbinPmD2SWgfOY401zCbAN4VJWIdDLPkNHop04h70Da5TBpdM1nqj5Jx32suV2pSQsJQ/DKu74T54rLd9xvQKSDjHUEgQSOQFxTxf7UquJSiTu6IT0aBpc5S92B1Z59gbYpk++Y64KJIoVIbueoTlUobtT87JIBLcNXdB6TP4+EScQvdy9dUneI1F77yR5fTLIjGG8I6HVCmJ74myOt3C2T/LeAXszM68aLODkLBbqHC79rkqH60h	33	16	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDivse+1K50W9pdrAF1l3EAKk4xWBRHPBewYrhnxt3uL9Y2ynglcpgZZ9nYjtGKYgQRu8V1j2rZxiwFWqkP+ZC0dGfs5IRN4CwnQvwNXoJ7r6WwcOU36YWGIN/J2EdIhek10LJmQkDHhYnYSkn9xzS64w0XpmHt4V+8bu3EvVeEHXS6iYMdyTFusFBS/GnoaMLT/slQaf+Huo1TL3snBnlI/SoLSKGjyO4+KJ2YgqmDkVISt6tzoaVW1Kjht/8V8jmNMjUDAKF/xxMVATf7s57jKneSTV1u6OneeSJsv7atkwR9mYop+jCCvrQf/mQPaLLBfn5So2vOHHZNQ9992RqbwDerdVjnEO1HZilpjHfoh5aRU9RMCNcxwb8Rw+bsGBYUpKsDCQDI21yIamHinV6qZtY0gCbMhDX8iUM54CtjpmKv5+cnnB6rbuDXfwOzgdsNW7FPXQo4pTvGI0Bj56rTFTAcJpS9RxSU/fdJCwfOsegGZWrQP96dUA2GPWC4ArM=	34	1	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDoGW5u2pB2/qYaG/zYnG63ppf/wP5SNIlY9FZrysVML3i5L/NdWF0W2PU+TKdvMeWwo5SZIPl2sjMFCYiucShnrMe+2g7Z81xqyfKHTuIRDDWuqbAmMLVq8YcNHk9aPy6SxHW4/mfMroyMfNBML8sGqrx0VYG6ySezecLgNiNxb3SSA/DIXe+pNvj+7BZgUERiItiGc9+Dkj1R8ZxSW2A6UDLwk7FvD9QI6DYoWz2upfNYdFQhZWoE+QKSD34dRYf/mUFS12RFzbdfCwWcOIW7lMenxpd7HdmokAKMvjer3H2d2EztPkxcSyIGEOCzgiMcU8nJuSk8k+eAKw6BfAkGzHiAlEn5l+G3XdaWC0kZXgXnNZRKf5+TCdO4yR4Jeli5sfZVk8Cg/iUqJDqEw8rYJLZw7ArkaTLauozdXSGJLnCu/6YQIAbp42t3qkftLMK/lzqBqlHzw/nNTn2tth8JwfEdxSWd9FDVTLPmbgn+VSQjFhN5rLqodda4N3JphEk=	35	19	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABAQDiVk13CvB4ZMHt7HFbi9sPePiw2nTorcsaV481uJ5gPcjqQQZDp27dR12ObkFYyuPzoV2qy+zvvaCJBphaz3fi8XdgE2xLuLPRMGILohGoJGOqfsN1t2w98ne8x6CpPiwscsFIUCglKDUT0MxpcoiWmaeq+ZEj2RA3v2kBr4FNPImQIzEN8XSYhuv3iPZ28n/TZzAUUvzl1KkjylHpd9hx4Xd2IVf7RF34OvwNeGTDAmq2DmWg9K6wgotgVH+YdKNYVI6CCj6lJCV37wdYrM+TepqNfZXSqq17fvflATdlqb3P2PIIPTT6831Tq9T2NIGE99ulTUq42chAM5E4gNdV	36	30	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDibJc5hndetpir8DI6o76ZmGdRzf18TRP0wf1KSjnnmHeiJ0zXQCQ0lyFjK2PZ/W2zdepvmOtBUIB7oQN+Hitz71FZZfzk0Y4B2egPeWuww4JkDlU7aDPemPtoALHy323Y1pbIeZgVQqPr0PMbPfCr/ivkUI74tSrSpJKoW4TeeU/TuZBsgDth4pCub3HtK9TFwIrnHwv3heYpvAbCDlRLZXNJCCyQk6UznsjXEHGPMrbPf78e5GyKmE+IElMZgmEOYKo4KPZfYKT7LggXvND3xPu/ortUFVa85uAPsFns838d4BYPstPAGwLkZCRQi+QTM+R6JdkLFkGSBEWKWK99XMzRrdnvWdWRqUdrWrR+mRLSD4AlvmP9gGL69XrVOZ1YQYorSF/849sP0X+OTV938EMNK3GLQrxPyw5qYi5Pptevd0tQxp+fKwx2nA+MlUbemjTdlBwGb2PRkcK1cJf4z1UvTN1rOgI9NzcSqXNeAK7J3H7MJZ9VWwnEQVq3Ci8=	37	29	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDJwGVhPZzW8/c4x+xJPXpzSVw8dCi+3Rwt3pFwe/u244Hp0zBKmJCjIzHqpwaKuavpcXojUm16o6+znfDaaZh3mO3ET7k8chEComJsLYsLWruHTQ07rI4xaCFDB2fWFF903xpSJRVtVPjsr1GPDVxx/34V8dPc5p+thF4sh7F/TWZ+7gHKLY2T50c2BkcQDQ3oKcWgzEuc8fqWAYFkZXJzGvqmoR9QGztU2RBs0Q+lxDc4nb4eUOuHK4KUIBGDdZzU9I67Ie/PBNjZCw/U81qG6KCTYumU0jNuh+AAKe0dsy/US6HU8Xzmz4tqTEA3d8JTv30qL6u6sXecz9a700T/C5dC8mnZ4q+CpGqA+1Kzt/eAk7HJVs+hblNZlkjGNYH1hW6UaWaBbtsC+8pkKq/kJOYKGXvJb0oupxE9liGDmIIsP7f4hV3lHv8NDNneXuE53iJrteZ4dq/GjZmxRKIIHgoScfy9kT8uE0I4MBMSRkIL4NxYp2Q7+u++9iC1TxU=	38	16	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAACAQDyHW4u6D2Aa/v1Z6fUSz+HJx4kAKuW2bN/ioOm5m0O14qyUb7+1L0vFAkIDcWtdLo5QXsHlyvCyJQqzkoYYMrwaZueJFO687cLf+iF2rrXpzsEX70NEjCSSVR2T+X2Qsp/P6qpaLPSBnmPX0j4mMNmOSGLLbH2K6Yz+j0p9zKoz719gEOQD+iCQC5JlxrEPdeEoCVxMTbioNOu67gPwwWXXkBhq1gqJxEriM/SdiEGOCN34EQyXO8aWDZ//jGUNCNiNxLydYgJiWHN7jjEUAOV83pMteqZYnJbSIsZch6dMhk9hQvHOvLx6N6Ou2Vpg3N98tSzFjEpeu4l5Zg7KZ6HbyXBTnUNFYp3tjjM7K/bd4HacinP8MzrfxfQ2CVNjeSfsPCKiEOuilSqKCdSDgy5tzzQOLBfTDJEZ+l0LdJCY+Q0Y24eW2DKpdypdp4Ifvim8kk5qvWqN0peeJ/YelGK19VCLblxvsskiuch/3TtVh9bgfmxNMZ3Qw9+R7ODLuijY/DrED0MH7k0pYag6LtSJCwPHTf13tVfGogyaUhiVcj581VQWXBjxPkrwZ1j9NUdzpNuRgvcHbz1ofzPbhvxcUFEtx9IB0AC3SFUl18c3etBttn3oJq5StQxScGr9SPYt1R1BKtDRS1GkUKzCw73AeSDImZMl2y6ay//OjR+xw==	39	9	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAACAQC7zQbsD0B4cGFmANf8313USKomV+ob6J1/MQ2T89sytM/C7cVQObXWYnw/AzfveZst+CSeUc0MGXgw52dkm4gm4nC8TSVkSchNljkzLyAfw3x5IfxKyPeHDz+LnCEu5YIEoqrCl7g13WFvyg0Tu7qhX1U0YNLWiYxbn2cX+L/TsxWpYEpaWjjRPHUxobH0SC0V5HoADuJ6IDZPbKmUtli6eRVlgsiGwuJenmBVCLnHWKil7tMAt2YsQ5Zu5De63kOYU1pTF5C+iHe5ohR805w3wSC+aYvjd9Jy4UcdMYvwbgT4BHOA/kh59tNOKpa23SD7oOoY+003ZG6UZYx76oQfGoAK+Ad/5mktn8xZ4z25231q9NIN3q279nMNrDWzTeXwqzP6Ly3ON2q3yf6OtEsckCJSWwShs38O9ZgEygabatYuDlbssLkn4OtU5uVAIdSnhIqjNKA2MlgUXwwqZLCMTwJpEAM8K3EPvUvoY+vo+MZtADLVsVTx5Z04mNra6hAc+9SMKlGfJml8Ljkkf54jgS0Ii8Y5SDiQgC+3lqiE/o9FjFcuP+W3YPKv0BjjK6an5oJ0sLSq5EORO5fckjcDb/zdjSQbhpGmFSDjzR+aL6dP1vIBHoY/gtlG0Pibf3ryUopfkgj/zFvF3e4LLtJzwB7pkgTBOfiGS8d2CHNEwQ==	40	16	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABAQDICaR5Q+o2ZA/5RZ2Z9u3oucH1gENbZbY9O4tLv+i51B4qTkJAjCUG1R5G186fPZ8e+0AA8wGDP43s3YBgl5UheGGWzZKDgvyo0CJF2OTvIpS6Tch7M1rBBQEvKf72hP64O148cQD9Jxjgi5ZWiUIsZ4CF5dQiYYVl0p9Ye761Pj7ToaB38AbQy2qCNSYnDWNYaDBOkV3uE0i+QZJ8JI+e2BaXEwurnRj7RF7LtqhqGoPro0lVXgKeRho04XDSfPsU7IrZ6k5CQF9AcSSn00xHYv1GhfAkCb2ZdPCYHQR2WaAUjxjZbV99B3YrsbBC2ubf/nFWGRDBsZckIoBVT7dR	41	9	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQC7csECybflqCRdH/Hf4ObJ87jq98dNnG4MxBB+863Lj5m6otRPFh5v4sMaiAuVKiuShFuEmnCCqVZYLHe+OdVjW0W4pNWvIncO+FyY4hwJ05J6iPA5FjeaYMSZA2AgyiGv5UmGGjsBP12lI9cCS2m8bxd4EjdbyiCxySR/lE2cDNZ51RJtPBHDEzFQ9xrlHaem3rtAR1TqKdZrQSg9Sgp6MgBk7MzpgWuv75fro+xbuURc3R5F8YeMUXobo0QSsuzBfMwK9PN5mrg9AwrBZvlDn1M3cU7qOTeHOpnbOLSB/W2hDBqQcI0eE65qmZvF3yKhUgjasxf7P5Ftc55TiRiRaV86LdI9+0ay3ZtpMypi9599HwnZEhQd793r/wvSeEm0AAgneBHuG/fHj3BQmKvZm6B4hHFvdx/K0zFMUd697ajrmuEftCKpVdMzIiGhcJV6bhqHmBmohMiWnl6QQgCCPcI4wjKbgrL7oi9fcrJh0olxuskQrzLsM092jG03OMM=	42	26	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQC7csECybflqCRdH/Hf4ObJ87jq98dNnG4MxBB+863Lj5m6otRPFh5v4sMaiAuVKiuShFuEmnCCqVZYLHe+OdVjW0W4pNWvIncO+FyY4hwJ05J6iPA5FjeaYMSZA2AgyiGv5UmGGjsBP12lI9cCS2m8bxd4EjdbyiCxySR/lE2cDNZ51RJtPBHDEzFQ9xrlHaem3rtAR1TqKdZrQSg9Sgp6MgBk7MzpgWuv75fro+xbuURc3R5F8YeMUXobo0QSsuzBfMwK9PN5mrg9AwrBZvlDn1M3cU7qOTeHOpnbOLSB/W2hDBqQcI0eE65qmZvF3yKhUgjasxf7P5Ftc55TiRiRaV86LdI9+0ay3ZtpMypi9599HwnZEhQd793r/wvSeEm0AAgneBHuG/fHj3BQmKvZm6B4hHFvdx/K0zFMUd697ajrmuEftCKpVdMzIiGhcJV6bhqHmBmohMiWnl6QQgCCPcI4wjKbgrL7oi9fcrJh0olxuskQrzLsM092jG03OMM=	43	26	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAACAQDdBheuAIqGuOFyVRxntmexROn3lEnBwPGaT3i9ZP0wArNTQrDCEMPHybWj5BcLrdkYeu8LBhMxerBeNxEXJ22XNHe/7dNpzrzNT9wggUM+fwiE27g58OsibPySpbMzmqTfwhMIDV8Cz6763AAiOasLXOMlocD5mhVc5VlbyYYhzueX37Nhi2+8TM5DbjxOI2SZ2l4d8UeDkfN9405F51QDoQ/JjTzrtVF1G13O/5WMDU/6V4KPoVeaQV/PbD8fffAQ+EtcQX/bFXYkWfXRtAeV3x5YkGOdM/jvYuU2m9tfw3gHlmGKuZd8nXemR8TopBA160TPB/s5+k0j3MhBAufNRVEziemE+vGftwYCPE7nLC48j+h/7y32cmfsecnVDJX0aeyEXEdiGppA/D6Z4S7yC4BtKqSH9I1ygPyAdsPUbU097KDuaaAoaYNOctOdul8kiOYXgYfqyxMniuSm+nLbFHON5LaWQyYiSGImcTAa4rTxhQ4xlnXMkEnR8yi1eAgkueyvxX4sgTSohlLNOpPWJ0GWFL6DvfWqAnRn/AcSV02p+bBvFWDap551ElAQhcUD4VGz/uxCqlYj2dFuUeIb3BfI0NbV/lbxDbsRk0FhbM36gRJYIKlJz6L6JhVSX5ivk2zc4OYEyk2Ngf7UqM3fep4/LB+2rR65u8sSYKYSZw==	44	32	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDkDY6il7hSeiM8WDrFuuWB6OnI/3ihHzCevGhf+GHNiQHCwLwO3Cufiavldmzy2UMQuxhoydGD0Jxtfyx7rQ5HuYeShjRql2FDTkw5uaoSblzbkuxzdzY0eTfES58tZtXO88OXkgxa1yPE8U246TMEvLeA7txNyP8anMOQ06h3ys3af43fCjglWk3FXe8BF2/cV48VdbfKgJ92nkjuDxF2EsyznbIPGllsHGRvoNEKPrwZq8uHEllSmPyGd6Vq4sNeHa4oXqDtjPDy/bfeYnBNXykiR51ARMhgwaWUqsX5++kCJSxPtw3mNnWaeC1Iew+0U2qmaKrIlxMbM1nr9z64bhu26Ge0MbTVq1mEgy6RmBULSypdKcrOd6aBdHoJqvDGAFMLyJwDzMbAoX9z2bcUSkNX2xIL8iTq4ot4qG32Ol7305J1b/+K+3GJgMWIA1D6siOectepEPyf5LYx1CH2U13OxBGiuxMnrpvBQPdQUpYpOc2/ZQghXNF8NbMdVHs=	45	33	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQC0OVBlbgAUyVZq/wLlrE/u1OWw1SfcNISmvPCt9LP1WGOmNhJVM3YcZ+m3cIMjIshZz/d2GsIxY9J8+lN1zZsu7kGLl/Ir5ATtAuxrGyAh8hfK0mvqR9W1oqIJhUlnGf32JcmXSccNzxEJWn692UdhOImI79XzhTIBNsP3KPzDJkvrV6x23rL5e2HSmsNaz0pBsLF87ySBypFo/ytHvqvnXplNDPvlGe8LxLfuu0TywvFjk4tio5iuTilxxdA8EOV1r+yeKgpcVvZ6Q+EEPETftvpukF4Kpr4wn9zMFClI03NcqFK0HbdPWJxrTv2OXIMLKBERIjKd8lE/hztbo6/JLIrN75e90kTg3kadAoqWod6wOvXyEcbWMUcsE2dmRbC4tAQx+Z94NkbD0cmfrzkzzfecgKPqWJq0Kqth5+ahA+dDzYcW4ZnHAYvzVXCkacwqLWxBVukEZMNiTAfVMssBNDvIY0ZdCaCp8027Itu5s3N09qlaaecBz/pl59vIunM=	46	34	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDFV1Zx8HQGNkRm5DaizC/zhE3u7rsZgx/nw9/M5LF	47	35	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDFV1Zx8HQGNkRm5DaizC/zhE3u7rsZgx/nw9/M5LF	48	35	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQCVhADRHs/m0yibiu7RZeY7ePIrZwwUXDajBukwUGCO1X30iDbQU+Pzwr95NSPJG2ob6AbOj3Mnng8P/fJxNOYwgXyURRYqBJm1PBxx5snKMxHglQyo5RxqCIxcpMRbI7IiTCeRkDbH1qDliwCahN35sGnzybenP/WrJ2TEacEcPUoGwdg182dvHfoWuP7enkYU0WUFM+56I25IeI2XdWqX80OlycDJlNF2JlNR5Fc0vW0awoGiPJBjoHLLRI4cJp8Dxkj5m43/TUIS+PMnoUrxQcfrs9pfkTv7WT2yYgJAaVts32kgLxuQiOgiY2CnfJ/QxJD818trGuncaFzQ2D7N++sGswwsVAIZ03AcLdFYk8U/AdTe+goon1mOxm7VxUJ8dAnzvIROy0WvEUBnGqZjMa7JWSb3gMvUMY2dzfanuHaaGknKfk0Jy7qP5aP22IPBlSBmJsYOA31esjp6/qaIXir3eW7uvTJBbSZfAbU7HjegZ0zJJJmNljQ0L4r4P20=	49	9	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQCtMG5bVYbPHjAhdR8GBlshHmCSGWjSAM3wHnlW5As1gzhD4i6vqnPlmdgIPhZcdkg0LeyC1trRnErcP8jMYzBBr29p9uewFYTNPluY43WW8d4kFlrPrBRotj3YtyhG0pRUPIoe+ZEG2+O/01tCstQ8y9/f8ICcIo4qFPe7XFfmCKRVg2kAtYDb4SkVJXMz03o6PNRTnaV/6yImDjTMHPp7qrakdDjgb3VFT3S+oCIkqt1/Ed7umyH2jgXQOTf+E39csETwvQJVoJLvJ5PVh5j469NB3EpvT55HCGnAQd9BwNBCEzhWzcWqyz22QvOakBVNufXlyGjhbOyMqrMwGkdC2TuIGx1imrZH0u5aYABVP9ioxtdE44tG4xqbeQxV72HWOIdoWbQbIZjBbRcmmxcNkWHVvpdaQBjShO7dOmqoGoJ80pJlMJZj5+eeBruKWVeavJ+WH6weoth0oaKN9kCQcZ2Yn0lHSnnmoBIIA/bKmG+IsnPcm25VAH0CJKFAn68=	50	38	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABAQDkR9d0xaFnfVDyvfR4zqw1k/W+SzsCTh8xaot/UTqRrXr3hJu5+Jp4rrEX4db2TYD89j5hOOU5VwaPkRtUXAT1/8S7/j5o7Xzb8wy+J6VipzJiMQdYBq2v5yw9U4n+fJTzrYCWUn3y3GsAmjEkjTdErsNpCVAT5m86oH84fefOBW81egSDqH0Nre1B+u8ZiLQVWPbjlK7AOQHf7xgMg+QrSmmyMuyDYi97oPghOKxqBaWfsZDfEZaj3m2MRv6QPjhRZAHZNOZF7mngOp2fybn+AzVLYYRl7ljSAPft3jyRIid0H3MxYx/ZXxwItEw4HIOPe42GSP09Wa2UaZT0ZdQ3	51	5	ssh-rsa
AAAAB3NzaC1yc2EAAAABIwAAAIEA3D5KjXV/kCbXi6zmh9YBTCpzZZ/PT0LAiwwu+gQxFNOeCaAFBvSycHb52/tSfqpX+tayJgsX726lmDndzjkEsDu9G1UjYlMnh/mzeBJ+hNn0vs+47r9uQH4ytRKNXoKvXrIyVORNJ2DnReAtbziP71TNm0iDNkq1x634vwDm9ZU=	52	10	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQCxD8Ekw4gt84gkmMkpLzKbinmVc9Lcp9vCKE7+sIyqq05H8jkneDw5FS6e6EUgqY8LZAa32y4mM40wEEhvVKh5NoThf3TLUtfLU1WfOtYquLVgidI/Oy9DDCfkDhop+oSgEHrFQb/CWfGsHx0HDDMJKaUrji7etsIYfyCF1jRqxFJvDWQJHqBPN0a2y/kOyjozUzndD7SD6u1zRlxNiZND35kWLrzqJ6sAt16ZjX4+HzLeuz8yO3AVkZvCDgGcAVuMzsY+N//9SDJ8A+yyN+/arxXTb2p8fBCH8x1/LFiNTTYFski6fV5fwDka+9rXwnC4FBnp/xYjXQOGQgFwCcVspjEgZUFx0X/e29cjdrx588tp2Iz3QbOHltVSjPGstOwxInwGV/rgoNs4VXsfwrECr3EJlqMDZCskEhCejr8NY4vihsONijLKLW7DQAtmwQFlFzOw5zVL9/nEQmhmQ8Ss0DfJQN86DfFvRPF/c7YTKaHUj4gltMYBLC+TFiwCmKk=	53	43	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDuttiDTmUrP9XDHxYGLohhnebBG2m6snB3u94yh3Q5ZVhiwCmNK7hC58UG/LeAsEeIVZMXgqseqTzmu6qB4fHdOkqYfloaF3OIzXi298otV20m6fqd2BhBiNT1lF8i4Z0sT6r8qrxSF4VhVbWwAcFIOpEVYLZDcg8K6+mQNrApRKE1w2n0IlMBklCOHbOmPAyp/TwP4Ii6AVeHL+t/OiXDYk64eNpe2PSaW1pmDfKh+hi6KyTvZGxpunXYjDkWaLljc+IeKbTrSJDcv9QyWnt17LCw9G1DqH7nXVDlN1bnJFEb3AApeLTvqiIslygC1K8lCVfrx+RhhVpQZATY51YiaNlHldCGo2mz9pWGHhFUixmgGEEyL/4Mc0GhgQKW+6piZOoOzjsFW8SdZf97eFOX1saqloQYinUcBg9xza3pBKd0J4tod5mvabVbSoukqIVgiRrACz0wsP9gZnjxsBywI2wdXEkh872tv909JgdYjcQ4zZ5kMDKGaWPoI3jpqyE=	54	43	ssh-rsa
AAAAB3NzaC1yc2EAAAABJQAAAQEAjU3KzcGmhxKxbEGKGELUlnWc2G1qV6gtN6eQBoeXSdRoUS/VKH3tuEhEcpochwwt8m2p1OpVIIqBgxt3o1mww/cLXg6j5fP7ZYmQzA9bMHSJhtsFPZu/x0VDRoy73UQbc8fRU1FBFvlvnnuoGz7fDclUbGeAT79Zz2Dhyi8+l4dAqDjKziKSZYyLmfMzCP6jJXB	55	21	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDAPz1ZnRSeCFWnq2XC/9R1KonHlIyzgyJomYdi3zIdU18ryq6QOtMBBR5pGicLudO7LCMTPqF2qbTtqFxr2GjETMvFtjYcojATJzio1KBz0107kRhJnyygb0s7nMgpFDW30ARmuGfHayBo/5W6dVqa5wKt0HKbPk3lMdytbPGmALTYYpVN9TvKuL+cQ4xY41p3fN4uxVvFcVU0MTyaY1YiPyVI1XkvRBHMQRVCw2dXGoysPm1FRVXO5aDZjMX9301NirULt6po4T/Dhz4OZVTnMvHeFpp/tM0pWlip0hcCm9PAmCUW+C2nCKOh6uLWkUCCO8bJNb9DNmfgqcLZYvBTr58ipUtyoSQx+8ZK/U/qi0GOJr1prkquT5CEDXZPjzWuszXHmkTda/zUdm/Nu+dRGb1ABJYZ2JqnN5/kcSJeRmi0Dvml9OJMOjQrXKfLJ+JotxrTLhkUI/iKv3jENb7V04pSMUKyT/SohspIsQaHkg4BEztBqTXIS5zVgmEtFKc=	56	44	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDiNMr5bN+qDmSOmW31Ns4sizzJTj245Km2j4SYifTPeybgAdant50m9xq7Jrj1mbfBIlIiQcUgcrVRGLIVDucl9Fjk9bZTeJZ/hJgKMJ/ojtCM7IXsi+qBx2qf3370R6TeaX6KjgO2KZTAkb59zTsiuBPO9HLn40iBUqsiZhRk76uh1Msah0lpK6KaKCIjwpbsQbfHaqIJWEWTIKYAa+y9ewVycItFv2tTEvLt2geEh2wSr+EYiQvQUv/kLpr7v2VtOFxE1fw2CJBT7zH7eYA86EO0DP5Iywz0h9+FBCh2uPYb+hEymCP4Ju7s7/XWuFHVNB7jKWgx/YmdkmXOnFfkkCLIyGycpvWJmGchou84/0e+SjWRjys9Yuf2Dfa1JOIOqsTUKyGHhFd9ZT19rYqW5MJtECrasRyZu4OiZo/+ZwQgiyOOjVcHZx7H1LX3ktJYSlQMAUc2YsjNpbLmlmbuobkOdy5w97+EE0ngsL8mLuxAlDts55T2vraRNohKSsE=	57	45	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQDiNMr5bN+qDmSOmW31Ns4sizzJTj245Km2j4SYifTPeybgAdant50m9xq7Jrj1mbfBIlIiQcUgcrVRGLIVDucl9Fjk9bZTeJZ/hJgKMJ/ojtCM7IXsi+qBx2qf3370R6TeaX6KjgO2KZTAkb59zTsiuBPO9HLn40iBUqsiZhRk76uh1Msah0lpK6KaKCIjwpbsQbfHaqIJWEWTIKYAa+y9ewVycItFv2tTEvLt2geEh2wSr+EYiQvQUv/kLpr7v2VtOFxE1fw2CJBT7zH7eYA86EO0DP5Iywz0h9+FBCh2uPYb+hEymCP4Ju7s7/XWuFHVNB7jKWgx/YmdkmXOnFfkkCLIyGycpvWJmGchou84/0e+SjWRjys9Yuf2Dfa1JOIOqsTUKyGHhFd9ZT19rYqW5MJtECrasRyZu4OiZo/+ZwQgiyOOjVcHZx7H1LX3ktJYSlQMAUc2YsjNpbLmlmbuobkOdy5w97+EE0ngsL8mLuxAlDts55T2vraRNohKSsE=	58	45	ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAABgQC8qnJxsURJv4i/FfHG/i8ATc5a4qJCKNbVAm7uDXPdhfWaFui3ZPB7fk3zVsEiCndgl4FH03F1ImukHze94CpkiDCOqWc3hbfm9okeNuD5PcOjr9A4VT887TXKBCdiyWn/U63WWEHwW+FtaxJ3LQbApHP7VvWAHznfH1mmxLQfzRA7IwwzhKSUhUFRoWQwKhhMh2eMdNanXo0va82dX5weVFy4KAH0yAyRc2D0FO+nU0S5jFO0xIrehuX/Qrkpc2wTTywWVPeW3vcF6czoB6+gI9bIqNLoGoSG4b2wXTQrS9DYh3B5cBOa5uOozWRgjLuaegFq6jirrj2MjTt4ReYpmvQbsMp2Jla4eU1s3HzSEgYoNz+z3ugaDaU4kQ0qhANEYh01IOaOfKOjRziVogenwYO2ufz1MYBIKeiMrxw/N8OHgTawmPftRQCKnRADbFhJZDADXvMwF5HZu0yUAOTWVg14YBy4sO8GDg69dWHYNuXYbgHp/o2JgegSAmrLlfE=	59	46	ssh-rsa
\.


--
-- Data for Name: submissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.submissions (id, team_id, submission, "timestamp") FROM stdin;
6	4	SecDSM{free+points}	2022-04-23 14:10:40.743622
8	3	SecDSM{free_points}	2022-04-23 14:12:15.293471
10	11	SecDSM{free_points}	2022-04-23 14:12:45.998643
12	5	SecDSM{free_points}	2022-04-23 14:12:57.526909
18	12	SecDSM{free_points}	2022-04-23 14:15:01.082261
23	12	SecDSM{heroes_of_our_time}	2022-04-23 14:17:43.780176
25	9	 SecDSM{some_text_here}	2022-04-23 14:19:19.033132
26	10	SecDSM{some_text_here}	2022-04-23 14:19:21.842022
27	9	SecDSM{Hope_You_Used_puTTY}	2022-04-23 14:20:00.871893
28	9	SecDSM{some_text_here}	2022-04-23 14:20:39.951318
29	9	SecDSM{free_points}	2022-04-23 14:20:56.567639
30	10	SecDSM{free_points}	2022-04-23 14:21:26.241726
34	17	SecDSM{free_points}	2022-04-23 14:23:40.206773
36	15	SecDSM{free_points}	2022-04-23 14:27:09.538413
38	13	SecDSM{free_points}	2022-04-23 14:29:10.101185
39	9	SecDSM{heroes_of_our_time}	2022-04-23 14:29:38.543286
40	19	SecDSM{free_points}	2022-04-23 14:30:04.115912
45	9	ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCbGA40LGZPdcrEvJCb3s9x0xhUI6W4O/B0WKg055O9PIchbl4evUj+lcuI6Vw++bRbrPti3P5msmmHrCexXq8tAvtxoKeT001esmDQa6F5dcogtAJDV/iA9xKdIR11hQrtXVyWISY6PdVN2XQ2WKiGDjohrUinIe5jAUOqAm6B8sBdeMUm9dZkqq83yYicEKUIFiPC87n4HNQygeN86QaPTdzF0ucVRHsMaJqbFd+Fle2XjeQklOWMWsvPCHxD2RwtB9w6xAx7kukQ5BInh5Zs46F4Kgm6RqhZxeDzXmB9ggZuWOXNWqldrHX71hRAnygRi0zdvvEM85SSaBQIFnplXoPME0IAGAYmKGFo5ZXEo17taPXISOfo6B1ueVrKv8Elau9L3uALWQZmwLZWWu1y9LXN90plHcSBjxV2puCNYOty6oxlzZevB6wv0QZ9ewDFhssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCbGA40LGZPdcrEvJCb3s9x0xhUI6W4O/B0WKg055O9PIchbl4evUj+lcuI6Vw++bRbrPti3P5msmmHrCexXq8tAvtxoKeT001esmDQa6F5dcogtAJDV/iA9xKdIR11hQrtXVyWISY6PdVN2XQ2WKiGDjohrUinIe5jAUOqAm6B8sBdeMUm9dZkqq83yYicEKUIFiPC87n4HNQygeN86QaPTdzF0ucVRHsMaJqbFd+Fle2XjeQklOWMWsvPCHxD2RwtB9w6xAx7kukQ5BInh5Zs46F4Kgm6RqhZxeDzXmB9ggZuWOXNWqldrHX71hRAnygRi0zdvvEM85SSaBQIFnplXoPME0IAGAYmKGFo5ZXEo17taPXISOfo6B1ueVrKv8Elau9L3uALWQZmwLZWWu1y9LXN90plHcSBjxV2puCNYOty6oxlzZevB6wv0QZ9ewDFh+kSaovbSrdwOTgtEj1P5oBY+KkumypPP0X8vyjXCaRwj54Nc72iPFNrhnOH5FM= on3moda@W-CND1220TZBSecDSM{free_points}!	2022-04-23 14:32:20.352258
47	9	SecDSM{free_points}!	2022-04-23 14:32:28.030608
48	9	SecDSM{free_points}	2022-04-23 14:32:37.17971
49	9	SecDSM{free_points}	2022-04-23 14:32:43.768015
50	22	SecDSM{free_points}	2022-04-23 14:32:52.676824
51	9	SecDSM{free_points}	2022-04-23 14:32:57.674666
52	9	 SecDSM{nothing_will_burn_us_out} 	2022-04-23 14:33:19.214114
53	9	.SecDSM{de_la_capǎt}	2022-04-23 14:35:45.243457
55	9	SecDSM{de_la_capǎt}	2022-04-23 14:36:05.029256
56	9	SecDSM{nothing_will_burn_us_out}	2022-04-23 14:37:47.85044
57	18	SecDSM{free_points}	2022-04-23 14:38:19.461361
58	16	SecDSM{free_points}	2022-04-23 14:38:58.813817
60	5	secdsm{chal1}	2022-04-23 14:41:16.294835
62	18	SecDSM{free_points}	2022-04-23 14:42:06.576174
63	18	SecDSM{free_points}!	2022-04-23 14:42:17.426816
64	18	SecDSM{10)	2022-04-23 14:42:37.701154
65	18	SecDSM{bpg1_e2JwZzJf}	2022-04-23 14:42:53.262923
66	14	SecDSM{free_points}	2022-04-23 14:44:10.005886
67	5	SecDSM{nothing_will_burn_us_out}	2022-04-23 14:44:49.979351
68	9	SecDSM{bpg1_e2JwZzJf}	2022-04-23 14:45:18.870944
69	14	SecDSM{free_points}	2022-04-23 14:45:49.859646
70	14	SecDSM{free_points}!	2022-04-23 14:46:26.449704
71	21	SecDSM{free_points}	2022-04-23 14:46:51.931338
74	15	SecDSM{heroes_of_our_time}	2022-04-23 14:47:47.157031
76	16	SecDSM: {bbac5998-3102-4080-af68-7a061832ef36}	2022-04-23 14:49:12.350529
77	16	SecDSM{bbac5998-3102-4080-af68-7a061832ef36}	2022-04-23 14:50:11.4699
79	3	secDSM{nothing_will_burn_us_out}	2022-04-23 14:52:11.15026
81	12	SecDSM{nothing_will_burn_us_out}	2022-04-23 14:54:12.032617
82	3	secDSM{heros_of_our_time}	2022-04-23 14:54:57.949125
83	21	SecDSM{vote_for_the_winners}	2022-04-23 14:56:28.697565
84	5	SecDSM{maximum_grip}	2022-04-23 14:57:56.262007
85	3	SecDSM{heroes_of_our_time}	2022-04-23 14:58:58.496738
86	14	SecDSM{Sup3rS3cr3tPassw0rd}	2022-04-23 14:59:05.332709
87	30	SecDSM{free_points}	2022-04-23 14:59:19.142336
88	18	SecDSM{5-2-6-5-6-2-4-4-5-2-4-13-7-11-6-1-7-3-6-5-5-15-7-9-6-15-7-5-5-15-7-4-6-8-6-5-5-15-7-7-6-9-6-14-6-14-6-5-7-3-7-2-7-13-0-10}	2022-04-23 15:03:24.744235
89	22	SecDSM{free_points}	2022-04-23 15:03:27.591193
92	22	SecDSM{free_points}!	2022-04-23 15:03:46.683152
94	29	SecDSM{free_points}!	2022-04-23 15:04:14.458981
95	29	SecDSM{free_points}	2022-04-23 15:04:28.588809
96	5	SecDSM{twitter_verified}	2022-04-23 15:06:38.924428
99	22	SecDSM{chal1_hidden}	2022-04-23 15:07:13.212696
100	16	SecDSM{bpg3_Y29uZ3Jh}	2022-04-23 15:07:13.464154
101	9	SecDSM{dont_forget_it} 	2022-04-23 15:07:39.492433
102	9	SecDSM{dont_forget_it}	2022-04-23 15:07:48.6599
103	18	SecDSM{smelly-plastic}	2022-04-23 15:10:59.996815
104	16	SecDSM{8f6828da-2c8e-48f7-aae6-83f02ab7da3f}	2022-04-23 15:11:03.071623
107	29	SecDSM{heroes_of_our_time}	2022-04-23 15:12:03.278206
108	18	SecDSM{thanks_for_laughs}	2022-04-23 15:12:12.632689
114	29	SecDSM{when_you_look_at_me}	2022-04-23 15:13:49.888599
118	18	SecDSM{collision_domains_ftw}	2022-04-23 15:18:17.461384
120	18	SecDSM{thanks_crackstation}	2022-04-23 15:18:55.394576
123	29	SecDSM{my_number_one}	2022-04-23 15:21:07.095461
147	29	SecDSM{bpg1_e2JwZzJf}	2022-04-23 15:29:39.523181
109	22	SecDSM{free_points}!	2022-04-23 15:12:18.882935
110	22	SecDSM{free_points}	2022-04-23 15:12:28.520255
112	13	SecDSM{thanks_crackstation}	2022-04-23 15:13:39.180578
113	18	SecDSM{use_it_someday}	2022-04-23 15:13:45.582341
115	19	SecDSM{vote_for_the_winners}	2022-04-23 15:14:14.931772
125	13	SecDSM{Sup3rS3cr3tPassw0rd}	2022-04-23 15:21:35.514436
117	16	SecDSM{heroes_of_our_time}	2022-04-23 15:16:25.475445
122	11	SecDSM{take_it_on}	2022-04-23 15:19:34.306246
124	12	SecDSM{take_it_on}	2022-04-23 15:21:12.71616
126	5	SecDSM{free_points}	2022-04-23 15:21:40.436817
132	11	SecDSM{heroes_of_our_time}	2022-04-23 15:22:34.584315
142	18	SecDSM{62143768}	2022-04-23 15:27:03.80853
154	18	SecDSM{526562445241371161736551579615755157468655157769614614657372713010}	2022-04-23 15:31:04.716301
157	18	SecDSM{5-2-6-5-6-2-4-4-5-2-4-13-7-11-6-1-7-3-6-5-5-15-7-9-6-15-7-5-5-15-7-4-6-8-6-5-5-15-7-7-6-9-6-14-6-14-6-5-7-3-7-2-7-13-0-10}	2022-04-23 15:31:31.932014
128	16	SecDSM{de_la_cap&#462;t}	2022-04-23 15:21:54.726943
133	32	SecDSM{free_points}!	2022-04-23 15:22:51.62099
134	15	SecDSM{take_it_on}	2022-04-23 15:23:09.001509
135	32	SecDSM{free_points}	2022-04-23 15:23:29.971445
136	9	SecDSM{thanks_crackstation}	2022-04-23 15:23:42.851909
137	32	SecDSM{some_text_here}	2022-04-23 15:23:44.861595
138	16	SecDSM{de_la_cap&#462;t}	2022-04-23 15:24:27.528068
139	16	SecDSM{de_la_capf.t}	2022-04-23 15:24:43.8974
140	13	SecDSM{take_it_on}	2022-04-23 15:26:13.762252
143	9	SecDSM{nick_is_so_great}	2022-04-23 15:29:09.902998
145	16	SecDSM{de_la_capǎt}	2022-04-23 15:29:16.411688
146	16	SecDSM{de_la_capsemit	2022-04-23 15:29:29.931002
148	16	SecDSM{de_la_capsemit}	2022-04-23 15:29:42.304813
150	9	SecDSM{nick_is_so_great}	2022-04-23 15:30:27.261597
151	33	SecDSM{free_points}	2022-04-23 15:30:29.424613
152	16	SecDSM{de_la_capǎt}	2022-04-23 15:30:38.122747
153	16	SecDSM{de_la_capat}	2022-04-23 15:30:50.685323
155	10	SecDSM{vote_for_the_winners}	2022-04-23 15:31:16.836156
156	16	SecDSM{de_la_capǎt}	2022-04-23 15:31:22.518012
158	9	SecDSM{nick_is_so_great}	2022-04-23 15:31:34.68637
159	22	SecDSM{heroes_of_our_time}	2022-04-23 15:32:43.079621
160	18	SecDSM{5 2 6 5 6 2 4 4 5 2 4 13 7 11 6 1 7 3 6 5 5 15 7 9 6 15 7 5 5 15 7 4 6 8 6 5 5 15 7 7 6 9 6 14 6 14 6 5 7 3 7 2 7 13 0 10}	2022-04-23 15:33:31.898713
162	9	SecDSM{nick_is_so_great}	2022-04-23 15:34:02.918269
163	18	SecDSM{ebfefbddebdmgkfagcfeeogifogeeogdfhfeeoggfifnfnfegcgbgmj}	2022-04-23 15:34:11.857257
164	30	SecDSM{805f}	2022-04-23 15:34:13.819472
165	18	SecDSM{wzwtwqpavxzvzzezvzuzzezzvudzxwvla}	2022-04-23 15:34:30.320657
166	30	SecDSM{0x805f}	2022-04-23 15:34:34.771759
167	19	SecDSM{vote_for_the_losers}	2022-04-23 15:35:38.406197
168	9	SecDSM{nick_is_so_cool}	2022-04-23 15:35:53.475498
169	5	SecDSM{my_number_one}	2022-04-23 15:35:59.122047
171	10	SecDSM{de_la_cap&#462;t}	2022-04-23 15:36:42.204887
172	29	SecDSM{53656344534D7B6172655F716F755F7468655F77616E6E6572737BGA}	2022-04-23 15:36:43.133475
173	18	SecDSM{4A>,4)%\v=IA39`K39.V7ME=.AIHG}	2022-04-23 15:36:47.507321
174	10	SecDSM{nothing_will_burn_us_out}	2022-04-23 15:37:14.805117
175	10	SecDSM{never_gives_a_damn}	2022-04-23 15:37:33.603844
176	10	SecDSM{de_la_capǎt}	2022-04-23 15:37:50.632169
177	9	SecDSM{vote_for_the_winners}	2022-04-23 15:38:25.906251
178	18	SecDSM{BSidesIA}	2022-04-23 15:38:40.492451
179	9	SecDSM{my_number_one}	2022-04-23 15:38:41.045661
181	29	SecDSM{53656344534D7B6172655F716F755F7468655F77616E6E6572737BGA}	2022-04-23 15:39:03.516789
182	5	SecDSM{nothing_will_burn_us_out}	2022-04-23 15:39:05.157523
183	5	SecDSM{nothing_will_burn_us_out}	2022-04-23 15:40:03.451221
185	33	SecDSM{vote_for_the_winners}	2022-04-23 15:40:25.307884
186	22	SecDSM{take_it_on}	2022-04-23 15:40:25.401472
187	14	SecDSM{nothing_will_burn_us_out}	2022-04-23 15:40:32.850043
188	5	SecDSM{heroes_of_our_time}	2022-04-23 15:40:45.690211
189	5	SecDSM{vulnerability_verified}	2022-04-23 15:40:47.971817
190	29	SecDSM{are_qou_the_wanners}	2022-04-23 15:40:54.621623
191	5	SecDSM{vuln_verified}	2022-04-23 15:41:05.770478
192	19	SecDSM{nothing_will_burn_us_out}	2022-04-23 15:41:06.790394
193	18	SecDSM{bpg3_Y29uZ3Jh}	2022-04-23 15:41:12.752079
194	5	SecDSM{take_it_on}	2022-04-23 15:41:13.09164
195	5	SecDSM{vulnerable_verified}	2022-04-23 15:41:27.072389
196	29	SecDSM{are_you_the_winners}	2022-04-23 15:41:30.749737
197	5	SecDSM{bpg1_e2JwZzJf}	2022-04-23 15:43:40.219771
198	5	SecDSM{vote_for_the_winners}	2022-04-23 15:43:58.870913
199	5	SecDSM{bpg1_e2JwZzJf}	2022-04-23 15:44:36.595249
200	5	SecDSM{de_la_cap&#462;t}	2022-04-23 15:44:58.046679
201	14	SecDSM{805f}	2022-04-23 15:45:31.842046
202	18	SecDSM{vote_for_the_winners}	2022-04-23 15:45:34.932235
203	14	SecDSM{805F}	2022-04-23 15:46:08.56454
204	3	secDSM{Playing the Ocarina}	2022-04-23 15:46:36.401207
206	11	SecDSM{Playing_the_Ocarina}	2022-04-23 15:47:13.968496
207	30	SecDSM{take_it_on}	2022-04-23 15:47:55.40809
208	14	SecDSM{805f}	2022-04-23 15:48:04.186839
209	18	SecDSM{nothing_will_burn_us_out}	2022-04-23 15:48:44.803696
211	18	SecDSM{de_la_cap&#462;t}	2022-04-23 15:49:32.620721
212	9	SecDSM{not_a_ufo}	2022-04-23 15:50:06.723832
213	18	SecDSM{de_la_cap&#462;t}	2022-04-23 15:50:29.537344
214	16	SecDSM{when_you_look_at_me}	2022-04-23 15:50:37.296163
215	16	SecDSM{nothing_will_burn_us_out}	2022-04-23 15:51:28.202165
216	19	SecDSM{heroes_of_our_time}	2022-04-23 15:52:50.574798
217	19	SecDSM{de_la_cap&#462;t}	2022-04-23 15:54:06.878891
218	16	SecDSM{805f}	2022-04-23 15:54:18.714984
219	16	SecDSM{0x805f}	2022-04-23 15:54:46.243333
220	22	SecDSM{vote_for_the_winners}	2022-04-23 15:55:12.850447
221	10	SecDSM{be_a_warrior}	2022-04-23 15:55:41.653667
222	34	SecDSM{free_points}	2022-04-23 15:55:52.508535
223	4	secDSM{Zelda}	2022-04-23 15:56:06.599073
224	10	SecDSM{tick_tock_take_you_dancing}	2022-04-23 15:56:11.39972
226	16	SecDSM{nick_is_so_cool}	2022-04-23 15:56:15.225881
227	22	SecDSM{vote_for_the_winners}	2022-04-23 15:56:15.538054
229	14	SecDSM{805f}	2022-04-23 15:56:55.040892
230	19	SecDSM{de_la_capǎt}	2022-04-23 15:57:21.016555
231	15	SecDSM{just_like_a_hurricane}	2022-04-23 15:57:37.153826
232	32	SecDSM{nick_is_so_cool}	2022-04-23 15:58:51.265204
233	19	SecDSM{bpg1_e2JwZzJf}	2022-04-23 15:59:37.543656
234	26	SecDSM{free_points}	2022-04-23 16:00:52.98439
235	33	SecDSM{take_it_on}	2022-04-23 16:01:20.610439
236	14	SecDSM{bpg1_e2JwZzJf}	2022-04-23 16:01:25.028805
237	22	SecDSM{no_sé_por_qué_dan_tanto_miedo_nuestras_tetas}	2022-04-23 16:01:47.490455
239	35	SecDSM{free_points}	2022-04-23 16:02:59.796442
240	3	secDSM{take_it_on}	2022-04-23 16:04:26.279645
241	33	SecDSM{bpg3_Y29uZ3Jh}	2022-04-23 16:04:30.481734
242	16	SecDSM{be_a_warrior}	2022-04-23 16:05:28.77548
243	18	SecDSM{de_la_cap&#462;t}	2022-04-23 16:05:58.555263
244	18	SecDSM{de_la_cap}	2022-04-23 16:06:59.10295
245	18	SecDSM{de_la_capǎt}	2022-04-23 16:07:07.772459
246	10	SecDSM{lord_of_the_ping}	2022-04-23 16:07:19.33626
253	10	SecDSM{one_if_by_lan}	2022-04-23 16:12:23.284837
287	18	SecDSM{heroes_of_our_time}	2022-04-23 16:32:12.691243
247	35	SecDSM{take_it_on}	2022-04-23 16:08:08.614351
248	30	SecDSM{just_like_a_hurricane}	2022-04-23 16:08:24.75571
264	30	SecDSM{bpg1_e2JwZzJf}	2022-04-23 16:20:26.172508
269	30	SecDSM{heroes_of_our_time}	2022-04-23 16:23:35.807489
270	30	SecDSM{U2VjRFNNe2JwZzBfVTJWalJGTk59}	2022-04-23 16:24:29.343172
275	30	SecDSM{U2VjRFNNe2JwZzBfVTJWalJGTk59}	2022-04-23 16:25:52.443763
250	22	SecDSM{nothing_will_burn_us_out}	2022-04-23 16:08:34.626439
251	22	SecDSM{de_la_cap&#462;t}	2022-04-23 16:09:01.372346
252	29	SecDSM{bpg3_Y29uZ3Jh}	2022-04-23 16:11:36.444837
254	19	SecDSM{dont_click_the_link}	2022-04-23 16:13:16.607974
255	14	SecDSM{dont_click_the_link}	2022-04-23 16:15:28.336369
266	19	SecDSM{thanks_for_laughs}	2022-04-23 16:21:43.546483
256	15	 SecDSM{nothing_will_burn_us_out} 	2022-04-23 16:17:16.546666
257	15	 SecDSM{nothing_will_burn_us_out}	2022-04-23 16:17:26.83351
258	15	SecDSM{nothing_will_burn_us_out}	2022-04-23 16:17:52.946303
259	9	SecDSM{tape_ftw}	2022-04-23 16:17:57.137261
260	9	secdsm{journeyman_badge_hacker}	2022-04-23 16:18:34.011819
261	18	SecDSM{be_a_warrior}	2022-04-23 16:19:11.429823
262	9	SecDSM{suri_is_goat}	2022-04-23 16:20:09.344138
263	32	SecDSM{never_gives_a_damn}	2022-04-23 16:20:22.876645
265	32	SecDSM{de_la_cap&#462;t}	2022-04-23 16:20:39.418549
267	32	SecDSM{de_la_capǎt}	2022-04-23 16:21:57.494581
268	32	SecDSM{nothing_will_burn_us_out}	2022-04-23 16:22:09.729474
272	9	SecDSM{vote_for_the_winners}	2022-04-23 16:25:25.032978
273	9	SecDSM{vote_for_the_winners}	2022-04-23 16:25:41.321811
274	9	SecDSM{vote_for_the_winners}	2022-04-23 16:25:49.104993
276	15	.SecDSM{de_la_cap&#462;t}	2022-04-23 16:26:01.478214
277	9	SecDSM{party_all_day}	2022-04-23 16:26:08.848625
278	15	SecDSM{de_la_cap&#462;t}	2022-04-23 16:26:19.407723
279	9	SecDSM{dont_forget_it}	2022-04-23 16:26:42.814429
283	15	SecDSM{de_la_capǎt}	2022-04-23 16:29:34.925274
288	9	SecDSM{dont_forget_it}	2022-04-23 16:33:03.66445
299	9	SecDSM{heroes_of_our_time}	2022-04-23 16:45:21.031177
280	19	SecDSM{when_you_look_at_me}	2022-04-23 16:27:21.01679
281	33	secDSM{lock_it}	2022-04-23 16:28:18.266336
282	33	secDSM{twitter_verified}	2022-04-23 16:29:01.841025
284	33	secDSM{rwd_is_best}	2022-04-23 16:29:46.990339
285	14	SecDSM{take_it_on}	2022-04-23 16:30:09.005533
286	16	SecDSM{vote_for_the_winners}	2022-04-23 16:31:18.886818
290	33	SecDSM{thanks_for_laughs}	2022-04-23 16:34:57.477388
291	5	SecDSM{U2VjRFNNe2JwZzBfVTJWalJGTk59}	2022-04-23 16:34:59.001844
292	5	SecDSM{bpg0_U2VjRFNN}	2022-04-23 16:35:47.012722
294	13	SecDSM{de_la_capǎt}	2022-04-23 16:41:50.46407
295	32	SecDSM{fbi_van_13}	2022-04-23 16:43:30.90333
296	5	SecDSM{nick_is_cool}	2022-04-23 16:44:01.514038
297	5	SecDSM{Nick_is_cool}	2022-04-23 16:44:24.130924
298	18	SecDSM{echo_foobar}	2022-04-23 16:44:36.197966
300	5	SecDSM{a07be5de-daa8-4664-90b0-f95616faf67a}	2022-04-23 16:46:17.42125
301	18	SecDSM{take_it_on}	2022-04-23 16:47:04.540744
303	16	SecDSM{thanks_crackstation}	2022-04-23 16:48:02.429842
305	5	SecDSM{nick_is_so_cool}	2022-04-23 16:48:42.092058
306	5	SecDSM{fbi_van_13}	2022-04-23 16:48:57.527235
308	16	SecDSM{parlez_de_moi}	2022-04-23 16:51:32.592852
309	22	SecDSM{be_a_warrior}	2022-04-23 16:54:06.608605
310	38	SecDSM{free_points}	2022-04-23 16:55:54.540907
311	10	SecDSM{just_like_a_hurricane}	2022-04-23 16:56:52.614906
313	18	SecDSM{nothing_will_burn_us_out}	2022-04-23 16:59:58.864375
314	13	SecDSM{nothing_will_burn_us_out}	2022-04-23 17:01:55.787593
315	19	SecDSM{use_it_someday}	2022-04-23 17:10:11.761666
316	18	SecDSM{best_in_us}	2022-04-23 17:15:53.413077
317	19	SecDSM{so_much_material}	2022-04-23 17:15:55.724553
318	18	SecDSM{crafty_you_are}	2022-04-23 17:20:42.737023
319	18	SecDSM{party_all_day}	2022-04-23 17:20:58.666202
320	22	SecDSM{parlez_de_moi}	2022-04-23 17:21:16.731816
321	22	SecDSM{whats_going_on}	2022-04-23 17:24:02.096955
322	22	SecDSM{he_man}	2022-04-23 17:24:27.453587
323	10	secdsm{use_it_somedat}	2022-04-23 17:27:05.752376
324	10	secdsm{use_it_someday}	2022-04-23 17:28:12.700604
325	10	SecDSM{heroes_of_our_time}	2022-04-23 17:28:46.177626
326	10	secdsm{party_all_day}	2022-04-23 17:32:12.079606
327	9	SecDSM{how_did_you_get_that}	2022-04-23 17:33:51.480284
328	19	SecDSM{make_it_ring}	2022-04-23 17:36:38.091046
329	10	secdsm{maximum_grip}	2022-04-23 17:40:01.224518
330	15	SecDSM{parlez_de_moi}	2022-04-23 17:40:06.812541
331	9	SecDSM{maximum_grip}	2022-04-23 17:41:33.486146
332	10	secdsm{crafty_you_are}	2022-04-23 17:44:20.177785
333	3	secDSM{make_it_rain}	2022-04-23 17:47:04.540892
335	3	secDSM{make_it_ring}	2022-04-23 17:47:27.379473
336	34	SecDSM{take_it_on}	2022-04-23 17:47:41.870883
337	30	secdsm{make_it_ring}	2022-04-23 17:48:22.884227
338	15	SecDSM{never_gives_a_damn}	2022-04-23 17:48:58.219968
339	10	secdsm{nick_is_so_cool}	2022-04-23 17:52:56.526805
340	16	SecDSM{8162daa2-c1db-4322-8a17-ee3e41a85af4}	2022-04-23 17:53:18.675968
343	43	SecDSM{free_points}	2022-04-23 17:55:47.4915
344	44	SecDSM{free_points}	2022-04-23 17:56:39.494249
345	15	SecDSM{when_you_look_at_me}	2022-04-23 17:59:09.994571
346	10	secdsm{echo_footbar}	2022-04-23 17:59:41.863569
347	10	secdsm{echo_foobar}	2022-04-23 18:00:26.061636
348	9	SecDSM{dont_youdare}	2022-04-23 18:01:28.098039
349	9	SecDSM{dont_you_dare}	2022-04-23 18:01:57.525112
350	10	SecDSM{take_it_on}	2022-04-23 18:02:28.497591
351	30	SecDSM{de_la_cap&#462;t}	2022-04-23 18:02:57.574722
352	19	SecDSM{sacando_un_pecho_fuera_al_puro_estilo_delacroix}	2022-04-23 18:03:29.818562
353	30	SecDSM{nothing_will_burn_us_out}	2022-04-23 18:03:56.473768
356	30	SecDSM{de_la_capǎt}	2022-04-23 18:05:30.466472
357	30	SecDSM{never_gives_a_damn}	2022-04-23 18:06:19.851915
358	10	secdsm{thanks_crackstation}	2022-04-23 18:06:21.288647
359	34	SecDSM{bbac5998-3102-4080-af68-7a061832ef36}	2022-04-23 18:06:41.108955
361	29	SECDSM{bbac5998-3102-4080-af68-7a061832ef36}	2022-04-23 18:07:02.25642
362	9	SecDSM{thanks_for_laughs}	2022-04-23 18:07:06.594533
363	34	SecDSM{8f6828da-2c8e-48f7-aae6-83f02ab7da3f}	2022-04-23 18:08:10.873424
364	34	SecDSM{9029a3c5-96c9-45cd-9b77-72df48a030f7}	2022-04-23 18:08:39.050227
365	10	SecDSM{my_number_one}	2022-04-23 18:10:41.029334
366	21	SecDSM{vote_for_the_winners}	2022-04-23 18:11:21.331079
367	15	SecDSM{be_a_warrior}	2022-04-23 18:11:54.459741
368	21	SecDSM{take_it_on}	2022-04-23 18:12:27.012791
369	5	SecDSM{vote_for_the_winners}	2022-04-23 18:12:29.032597
370	5	SecDSM{bpg1_e2JwZzJf}	2022-04-23 18:12:50.39372
371	21	SecDSM{take_it_on}	2022-04-23 18:12:57.284979
372	34	SecDSM{bbac5998-3102-4080-af68-7a061832ef36}	2022-04-23 18:13:09.063719
373	9	SecDSM{use_it_comeday}	2022-04-23 18:13:13.237742
374	21	SecDSM{take_it_on}	2022-04-23 18:13:16.028765
375	9	SecDSM{use_it_someday}	2022-04-23 18:13:37.33069
376	43	SecDSM{Hope_You_Used_puTTY}	2022-04-23 18:13:40.712981
377	21	secdsm{dont_you_dare}	2022-04-23 18:14:19.568717
379	21	secdsm{take_it_on}	2022-04-23 18:14:57.193005
380	21	SecDSM{so_frusterating}	2022-04-23 18:15:52.556562
381	21	SecDSM{just_like_a_hurricane}	2022-04-23 18:16:43.083548
382	9	SecDSM{floppy_not_hard}	2022-04-23 18:16:54.453975
383	34		2022-04-23 18:17:00.333525
384	21	SecDSM{rwd_is_best}	2022-04-23 18:17:01.278071
385	32	SecDSM{Hope_You_Used_puTTY}	2022-04-23 18:17:15.167741
386	21	secdsm{make_it_ring}	2022-04-23 18:17:18.583894
387	13	SecDSM{thanks_for_laughs}	2022-04-23 18:17:51.713509
388	9	SecDSM{crossed_your_mind}	2022-04-23 18:19:42.336051
389	38	SecDSM{nothing_will_burn_us_out}	2022-04-23 18:19:58.280309
390	5	SecDSM{Hope_You_Used_puTTY}	2022-04-23 18:21:02.10347
391	38	SecDSM{heroes_of_our_time}	2022-04-23 18:21:56.032942
392	10	secdsm{must_be_desperate}	2022-04-23 18:23:14.715618
393	10	secdsm{must_be_desperate}	2022-04-23 18:24:03.254563
394	10	SecDSM{must_be_desperate}	2022-04-23 18:25:04.101808
395	16	SecDSM{vote_for_the_winners}	2022-04-23 18:25:17.553011
396	10	SecDSM{must_be_desperate}	2022-04-23 18:27:05.066171
397	16	4	2022-04-23 18:27:43.385987
398	16	SecDSM{vote_for_the_winners}	2022-04-23 18:27:52.99454
399	21	SecDSM{my_number_one}	2022-04-23 18:27:55.224733
400	16	SecDSM{undefined}	2022-04-23 18:28:19.625685
401	10	SecDSM{must_be_desperate}	2022-04-23 18:28:51.137001
402	10		2022-04-23 18:28:55.630739
403	16	SecDSM{best_in_us}	2022-04-23 18:29:15.519746
404	10	SecDSM{must_be_desperate}	2022-04-23 18:29:21.019573
405	10	secdsm{must_be_desperate}	2022-04-23 18:30:04.254756
406	10	secdsm{must_be_desparate}	2022-04-23 18:30:21.867055
407	9	SecDSM{strangers_are_coming}	2022-04-23 18:30:37.572778
408	10	secdsm{must_be_desperate}	2022-04-23 18:30:39.858984
409	13	SecDSM{heroes_of_our_time}	2022-04-23 18:31:53.591374
410	18	SecDSM{must_be_desperate}	2022-04-23 18:33:20.417534
411	10	1	2022-04-23 18:33:56.339801
412	5	SecDSM{bpg1_e2JwZzJf}	2022-04-23 18:35:23.562074
413	3	secDSM{Hope_You_Used_puTTY}	2022-04-23 18:37:52.258225
414	16	SecDSM{bpg1_e2JwZzJf}	2022-04-23 18:39:18.795974
415	12	SecDSM{You_Used_PuTTY}	2022-04-23 18:39:20.572269
416	10	SecDSM{bpg1_e2JwZzJf}	2022-04-23 18:39:33.76643
417	10	SecDSM{bpg0_U2VjRFNN}	2022-04-23 18:39:59.851066
418	16	ecDSM{bpg0_U2VjRFNN}	2022-04-23 18:40:00.523252
419	12	SecDSM{Hope_You_Used_PuTTY}	2022-04-23 18:40:03.336746
420	16	SecDSM{bpg0_U2VjRFNN}	2022-04-23 18:40:10.928829
421	12	SecDSM{Make_It_Ring}	2022-04-23 18:41:04.781023
422	9	SecDSM{just_like_a_hurricane}	2022-04-23 18:41:41.026864
423	13	SecDSM{echo_foobar}	2022-04-23 18:43:19.529223
424	9	SecDSM{take_it_on}	2022-04-23 18:43:49.519421
425	1	tacotaco	2022-04-23 18:44:43.445611
429	1	tacosubmission	2022-04-23 18:51:43.766648
430	1	tacosubmission	2022-04-23 18:51:52.422362
433	1	tacosubmission	2022-04-23 18:55:20.515836
434	1	tacosubmission	2022-04-23 18:55:38.022724
435	1	tacotaco	2022-04-23 18:57:04.270384
436	1	tacotaco	2022-04-23 18:57:11.708241
438	1	tacotaco	2022-04-23 18:57:29.745409
440	1	tacotaco2	2022-04-23 18:57:46.34308
426	16	SecDSM{bpg4_dHVsYXRp}	2022-04-23 18:46:58.183641
427	9	SecDSM{you_are_the_one}	2022-04-23 18:47:08.840247
428	16		2022-04-23 18:47:14.614339
431	10	SecDSM{take_a_shot}	2022-04-23 18:51:53.891291
432	43	SecDSM{heroes_of_our_time}	2022-04-23 18:52:03.299085
437	5	SecDSM{vote_for_the_winners}	2022-04-23 18:57:27.156338
439	22	SecDSM{floppy_not_hard}	2022-04-23 18:57:43.222565
441	19	SecDSM{get_random_secret}	2022-04-23 18:59:12.861388
442	12	SecDSM{Use_It_Someday}	2022-04-23 18:59:55.250205
443	3	secDSM{smelly_plastic}	2022-04-23 19:01:37.137054
444	3	secDSM{use_it_someday}	2022-04-23 19:02:06.584021
445	21	SecDSM{floppy_not_hard}	2022-04-23 19:02:34.317549
446	15	SecDSM{must_be_desparate}	2022-04-23 19:03:59.288437
447	35	SecDSM{vote_for_the_winners}	2022-04-23 19:04:13.75783
448	15	SecDSM{must_be_desparate}	2022-04-23 19:04:35.823845
449	38	SecDSM{bpg1_e2JwZzJf}	2022-04-23 19:04:42.900677
450	15	SecDSM{must_be_dsperate}	2022-04-23 19:04:52.86262
451	15	SEec	2022-04-23 19:05:01.683147
452	35	SecDSM{parlez_de_moi}	2022-04-23 19:05:07.840576
453	15	SecDSM{must_be_desperate}	2022-04-23 19:05:20.72873
454	1	taoc	2022-04-23 19:05:54.920075
455	15	SecDSM{lord_of_the_ping}	2022-04-23 19:07:38.618435
456	44	q	2022-04-23 19:08:19.643315
457	16	SecDSM{bpg9_dF9yaWdo}	2022-04-23 19:09:06.902012
458	16	SecDSM{bpg1_e2JwZzJf	2022-04-23 19:09:24.780181
459	16	SecDSM{bpg1_e2JwZzJf}	2022-04-23 19:09:34.333736
460	18	SecDSM{take_out_the_trash}	2022-04-23 19:09:56.769281
461	16	SecDSM{bpg1_e2JwZzJf}	2022-04-23 19:09:59.59894
462	1	taco	2022-04-23 19:10:10.395228
463	16	SecDSM{bpg5_b25zX21l}	2022-04-23 19:10:22.124347
464	1	taco	2022-04-23 19:10:22.705078
465	18	SecDSM{hack_the_planet}	2022-04-23 19:10:24.846539
466	22	SecDSM{nick_is_so_cool}	2022-04-23 19:11:52.166213
467	1	taco	2022-04-23 19:12:07.955554
468	22	SecDSM{use_it_someday}	2022-04-23 19:12:13.027442
469	1	SecDSM{free_points}	2022-04-23 19:12:14.954942
470	1	SecDSM	2022-04-23 19:12:49.33307
471	22	SecDSM{de_la_capǎt}	2022-04-23 19:12:52.88848
472	1	SecDSM{free_points}	2022-04-23 19:12:54.088113
473	1	SecDSM{free_points}	2022-04-23 19:14:06.148347
474	1	taco	2022-04-23 19:14:39.771121
475	1	SecDSM{free_points}	2022-04-23 19:14:45.696214
476	22	SecDSM{he_man}	2022-04-23 19:15:17.284777
477	16	SecDSM{Dual_Core}	2022-04-23 19:15:52.998922
478	22	SecDSM{what's_going_on}	2022-04-23 19:16:06.786262
479	34	SecDSM{never_gives_a_damn	2022-04-23 19:17:08.060781
480	34	SecDSM{never_gives_a_damn}	2022-04-23 19:17:17.803663
481	34	SecDSM{nothing_will_burn_us_out}	2022-04-23 19:18:05.106876
482	22	SecDSM{thanks_crackstation}	2022-04-23 19:18:31.626085
483	3	secDSM{vote_for_the_winners}	2022-04-23 19:19:13.827403
484	16	SecDSM{bpg3_Y29uZ3Jh}	2022-04-23 19:20:14.084627
485	34	SecDSM{de_la_capǎt}	2022-04-23 19:20:20.605072
486	21	secdsm{ride_your_bicycle_instead_of_a_car}	2022-04-23 19:20:28.101724
487	1	test	2022-04-23 19:20:37.934439
488	1	SecDSM{free_points}	2022-04-23 19:20:43.4242
489	34	SecDSM{parlez_de_moi}	2022-04-23 19:21:58.173251
490	10	SecDSM{a07be5de-daa8-4664-90b0-f95616faf67a}	2022-04-23 19:22:04.727416
491	12	SecDSM{Vote_For_The_Winners}	2022-04-23 19:22:17.762411
492	22	SecDSM{hey_hold_the_door}	2022-04-23 19:23:56.077674
493	13	SecDSM{just_like_a_hurricane}	2022-04-23 19:24:25.551346
494	1	SecDSM{more_free_points}	2022-04-23 19:24:33.726571
495	15	SecDSM{vote_for_the_winners}	2022-04-23 19:25:24.852422
496	16	SecDSM{bpg5_b25zX21l}	2022-04-23 19:26:31.7879
497	15	SecDSM{vote_for_the_losers}	2022-04-23 19:26:49.914249
498	5	SecDSM{just_like_a_hurricane}	2022-04-23 19:27:36.955727
499	3	secDSM{echo_foobar}	2022-04-23 19:28:03.498307
500	35	flag{chal1_hidden}	2022-04-23 19:28:36.049249
501	34	SecDSM{be_a_warrior}	2022-04-23 19:28:56.490958
502	44	SecDSM{heroes_of_our_time}	2022-04-23 19:30:21.371504
503	12	SecDSM{Vote_For_The_Winners}	2022-04-23 19:30:23.512015
504	12	SecDSM{vote_for_the_winners}	2022-04-23 19:31:06.218186
505	35	SecDSM{nothing_will_burn_us_out} 	2022-04-23 19:33:06.278109
506	5	SecDSM{larger_than_dreams}	2022-04-23 19:33:53.779015
507	22	SecDSM{smelly_plastic}	2022-04-23 19:33:55.660088
508	35	SecDSM{de_la_capt}	2022-04-23 19:33:57.974932
509	34	SecDSM{when_you_look_at_me}	2022-04-23 19:34:16.319014
510	35	<!-- SecDSM{nothing_will_burn_us_out} -->	2022-04-23 19:34:17.356612
511	5	SecDSM{larger_than_dreams}	2022-04-23 19:34:18.48074
512	35	<!-- SecDSM{nothing_will_burn_us_out}	2022-04-23 19:34:34.159358
513	35	SecDSM{nothing_will_burn_us_out}	2022-04-23 19:34:51.448828
514	35	SecDSM{de_la_capt}	2022-04-23 19:35:18.39144
515	35	SecDSM{de_la_cap&#462;t}	2022-04-23 19:35:44.927475
516	22	SecDSM{bpg1_e2JwZzJf}	2022-04-23 19:35:47.062525
517	35	No flags. . . . . . . . . . . . . . . . . . . . . .SecDSM{de_la_cap&#462;t}	2022-04-23 19:36:53.563271
518	10	SecDSM{a54a42a6-e2bd-46ec-969c-ea8f5741dc62}	2022-04-23 19:37:23.326625
519	5	SecDSM{larger_than_dreams}	2022-04-23 19:37:42.706757
520	19	SecDSM{take_it_on}	2022-04-23 19:38:52.818466
521	5	SecDSM{a07be5de-daa8-4664-90b0-f95616faf67a}	2022-04-23 19:38:55.168037
522	22	SecDSM{bpg1_e2JwZzJf}	2022-04-23 19:39:02.204591
523	3	SecDSM{bpg3_Y29uZ3Jh}	2022-04-23 19:39:11.085181
524	5	SecDSM{a07be5de-daa8-4664-90b0-f95616faf67a}	2022-04-23 19:39:30.475972
525	22	SecDSM{bpg4_dHVsYXRp}	2022-04-23 19:39:41.648671
526	32	SecDSM{Vote_for_winners}	2022-04-23 19:39:42.080599
527	30	SecDSM{just_like_a_hurricane}	2022-04-23 19:39:51.605863
528	5	SecDSM{a07be5de-daa8-4664-90b0-f95616faf67a}	2022-04-23 19:39:52.184909
529	32	SecDSM{Vote_for_winner}	2022-04-23 19:40:00.541935
530	15	SecDSM{bpg1_e2JwZzJf}	2022-04-23 19:41:30.373679
531	34	SecDSM{never_gives_a_damn}	2022-04-23 19:41:41.869033
532	16	SecDSM{heroes_of_our_time}	2022-04-23 19:42:23.899695
533	22	SecDSM{not_a_ufo}	2022-04-23 19:42:24.406969
534	22	SecDSM{deflated}	2022-04-23 19:42:45.425622
535	15	SecDSM{bpg0_U2VjRFNN}	2022-04-23 19:42:45.966023
536	34	SecDSM{bpg1_e2JwZzJf}	2022-04-23 19:46:32.208211
537	5	SecDSM{larger_than_dreams}	2022-04-23 19:46:38.99609
538	15	SecDSM{bpg3_Y29uZ3Jh}	2022-04-23 19:47:52.606897
539	16	SecDSM{S}	2022-04-23 19:48:14.106623
540	18	1	2022-04-23 19:48:15.126736
541	19	SecDSM{echo_foobar}	2022-04-23 19:48:16.686831
542	16	SecDSM{take_it_on}	2022-04-23 19:49:38.385932
543	3	secDSM{journeyman_badge_hacker}	2022-04-23 19:49:40.158988
544	3	secDSM{thanks_crackstation}	2022-04-23 19:50:21.384463
545	13	SecDSM{my_number_one}	2022-04-23 19:50:49.820466
546	15	SecDSM{bpg4_dHVsYXRp}	2022-04-23 19:51:32.581529
547	35	SecDSM{heroes_of_our_time}	2022-04-23 19:51:55.882196
548	9	SecDSM{must_be_desparate}	2022-04-23 19:52:17.553137
549	9	SecDSM{must_be_desperate}	2022-04-23 19:52:44.392286
550	5	SecDSM{de_la_cap&#462;t}	2022-04-23 19:53:04.448533
551	5	SecDSM{nothing_will_burn_us_out}	2022-04-23 19:53:12.622882
552	14		2022-04-23 19:53:13.477678
553	21	secdsm{tape_ftw}	2022-04-23 19:53:53.358687
554	5	SecDSM{parlez_de_moi}	2022-04-23 19:54:11.729885
555	22	SecDSM{idk_bm_wanted_this}	2022-04-23 19:55:44.463284
556	21	SecDSM{Hope_You_Used_puTTY}	2022-04-23 19:55:51.683816
557	14	SecDSM{just_like_a_hurricane}	2022-04-23 19:56:07.591081
558	5	SecDSM{when_you_look_at_me}	2022-04-23 19:57:23.913521
559	15	SecDSM: {bbac5998-3102-4080-af68-7a061832ef36}	2022-04-23 19:58:42.28666
560	16	SecDSM{never_gives_a_damn}	2022-04-23 19:58:55.904961
561	15	SecDSM{bbac5998-3102-4080-af68-7a061832ef36}	2022-04-23 19:59:13.737046
562	16		2022-04-23 19:59:14.284184
563	34	SecDSM{BSidesIA}	2022-04-23 19:59:23.137194
564	34	SecDSM{U2VjRFNNe2JwZzBfVTJWalJGTk59}	2022-04-23 20:01:14.501421
565	34	U2VjRFNNe2JwZzBfVTJWalJGTk59	2022-04-23 20:01:45.237815
566	34	SecDSM{bpg0_U2VjRFNN}	2022-04-23 20:02:33.41086
567	5	SecDSM{never_gives_a_damn}	2022-04-23 20:03:55.029161
580	34	SecDSM{bpg4_dHVsYXRp}	2022-04-23 20:07:50.531499
599	34	SecDSM{bpg3_Y29uZ3Jh}	2022-04-23 20:20:53.217365
606	5	SecDSM{larger_than_dreams}	2022-04-23 20:25:57.905034
641	5	SecDSM{must_be_desperate}	2022-04-23 20:52:05.724058
642	16	SecDSM{larger_than_dreams}	2022-04-23 20:52:21.309431
643	5	SecDSM{party_all_day}	2022-04-23 20:52:29.937795
644	5	SecDSM{thanks_for_laughs}	2022-04-23 20:52:44.901758
645	16		2022-04-23 20:53:04.503494
649	5	SecDSM{bring_a_towel}	2022-04-23 20:55:37.399799
568	14	SecDSM{best_in_us}	2022-04-23 20:04:00.10752
569	3	secDSM{de_la_capat}	2022-04-23 20:04:16.447822
570	14	SecDSM{twitter_verified}	2022-04-23 20:04:22.424733
571	14	SecDSM{thanks_crackstation}	2022-04-23 20:04:48.635478
572	14	SecDSM{thanks_for_laughs}	2022-04-23 20:05:09.496226
573	14	SecDSM{knock_it_over}	2022-04-23 20:05:26.759833
574	14	SecDSM{lock_it}	2022-04-23 20:05:41.496118
575	3	secDSM{de_la_capăt}	2022-04-23 20:06:08.113996
576	10	secdsm{best_in_us}	2022-04-23 20:06:14.840422
577	16	SecDSM{tick_tock_take_you_dancing}	2022-04-23 20:07:36.63165
578	14	SecDSM{vote_for_the_winners}	2022-04-23 20:07:41.990637
579	3	secDSM{from_the_beginning}	2022-04-23 20:07:43.5374
581	14	SecDSM{805f}	2022-04-23 20:08:11.830793
582	3	secDSM{de_la_capăt}	2022-04-23 20:08:17.918799
583	9	SecDSM{smelly_plastic}	2022-04-23 20:10:46.265664
584	9	SecDSM{a07be5de-daa8-4664-90b0-f95616faf67a}	2022-04-23 20:11:46.837113
585	46	SecDSM{Hope_You_Used_puTTY}	2022-04-23 20:13:42.326257
586	10	SecDSM: {8162daa2-c1db-4322-8a17-ee3e41a85af4}	2022-04-23 20:13:45.604216
587	3	secDSM{when_you_look_at_me}	2022-04-23 20:13:54.488066
588	10	secdsm{8162daa2-c1db-4322-8a17-ee3e41a85af4}	2022-04-23 20:14:35.588318
589	46	SecDSM{free_points}!	2022-04-23 20:14:52.134549
590	46	SecDSM{free_points}!	2022-04-23 20:15:02.827754
591	46	SecDSM{free_points}	2022-04-23 20:15:15.498679
603	14	SecDSM{BSidesIA}	2022-04-23 20:22:36.665923
605	14	SecDSM{de_la_capǎt}	2022-04-23 20:25:49.869843
608	9	SecDSM{idk_bm_wanted_this}	2022-04-23 20:31:53.484339
609	14	SecDSM{never_gives_a_damn}	2022-04-23 20:32:16.954022
610	10	SecDSM{9029a3c5-96c9-45cd-9b77-72df48a030f7}	2022-04-23 20:32:17.616349
612	9	SecDSM{a54a42a6-e2bd-46ec-969c-ea8f5741dc62}	2022-04-23 20:34:41.04165
616	10	SecDSM{floppy_not_hard}	2022-04-23 20:37:33.67804
621	3		2022-04-23 20:44:44.361934
622	3	SecDSM{vote_for_the_winners}	2022-04-23 20:44:56.839812
624	14	SecDSM{U2VjRFNNe2JwZzBfVTJWalJGTk59}	2022-04-23 20:45:41.007793
628	10	SecDSM{crossed_your_mind}	2022-04-23 20:46:44.180005
630	14	SecDSM{SecDSM{bpg0_U2VjRFNN}}	2022-04-23 20:47:43.213605
631	14	SecDSM{bpg0_U2VjRFNN}	2022-04-23 20:48:01.194209
633	46	secdsm{jouneyman_badge_hacker}	2022-04-23 20:49:36.477578
635	46	secdsm{journeyman_badge_hacker}	2022-04-23 20:49:55.716925
639	9	SecDSM{deflated}	2022-04-23 20:51:34.507803
648	46	secdsm{5156441001}	2022-04-23 20:55:09.619034
650	46	secdsm{1001hh9S1S}	2022-04-23 20:55:51.877893
592	21	secdsm{must_be_desperate}	2022-04-23 20:15:35.105617
646	21	secdsm{i_cant_wait_to_know}	2022-04-23 20:53:58.937745
593	22	SecDSM{burns_when_ip}	2022-04-23 20:16:10.554928
594	14	SecDSM{53656344534373746170655f667477730a}	2022-04-23 20:16:15.068121
595	18	SecDSM{hey_hold_the_door}	2022-04-23 20:16:59.357355
596	22	SecDSM{wutang_lan}	2022-04-23 20:18:12.443205
597	22	SecDSM{lord_of_the_ping}	2022-04-23 20:19:57.361238
598	22	SecDSM{one_if_by_lan}	2022-04-23 20:20:49.459471
600	14	SecDSM{make_it_ring}	2022-04-23 20:21:54.381218
601	29	SecDSM{a54a42a6-e2bd-46ec-969c-ea8f5741dc62}	2022-04-23 20:22:16.780201
602	22	SecDSM{fbi_van_13}	2022-04-23 20:22:23.951449
604	5	SecDSM{larger_than_dreams}	2022-04-23 20:25:25.198248
607	30	SecDSM{my_number_one}	2022-04-23 20:29:13.866795
614	22	SecDSM{suri_is_goat}	2022-04-23 20:35:01.417352
615	22	SecDSM{thanks_for_laughs}	2022-04-23 20:35:25.951418
620	22	SecDSM{dont_click_the_link}	2022-04-23 20:43:19.882512
629	18	SecDSM{some_text_here}	2022-04-23 20:46:53.531582
632	14	SecDSM{vote_for_the_winners}	2022-04-23 20:49:12.86321
638	22	SecDSM{dont_you_dare}	2022-04-23 20:50:36.905026
647	22	SecDSM{must_be_desperate}	2022-04-23 20:55:09.324191
611	21	SecDSM{floppy_not_hard}	2022-04-23 20:33:50.753872
613	22	SecDSM{how_did_you_get_that}	2022-04-23 20:34:42.277119
617	19	7	2022-04-23 20:40:21.776453
618	5	SecDSM{53656544534d7b6172655f796f755f7468655f77696e6e6572737d02}	2022-04-23 20:41:15.268845
619	19	7	2022-04-23 20:43:05.16426
623	9	SecDSM{so_many_tears}	2022-04-23 20:45:22.185272
625	18	SecDSM{password}	2022-04-23 20:45:51.27128
626	9	SecDSM{so_many_tears}	2022-04-23 20:46:13.230261
627	18	SecDSM{am_human}	2022-04-23 20:46:21.9825
634	29	SecDSM: {8162daa2-c1db-4322-8a17-ee3e41a85af4}	2022-04-23 20:49:40.365959
636	9	SecDSM{so_many_tears}	2022-04-23 20:50:14.73525
637	29	SecDSM{8162daa2-c1db-4322-8a17-ee3e41a85af4}	2022-04-23 20:50:20.369153
640	29	SecDSM{8f6828da-2c8e-48f7-aae6-83f02ab7da3f}	2022-04-23 20:51:43.907836
651	9	SecDSM{ride_your_bicycle_instead_of_a_car}	2022-04-23 20:58:19.52589
652	22	SecDSM{chal3_step5}	2022-04-23 20:59:49.933046
\.


--
-- Data for Name: teams; Type: TABLE DATA; Schema: public; Owner: postgres
--

copy public.teams (id, name, enabled, hash) from stdin;
1	taco	\n	$2a$10$0000000000000000000000000000000000000000
3	notsecmidwest	\n	$2a$10$0000000000000000000000000000000000000000
4	mrs.riskyclicks	\n	$2a$10$0000000000000000000000000000000000000000
5	ridings	\n	$2a$10$0000000000000000000000000000000000000000
6	real small malware	\n	$2a$10$0000000000000000000000000000000000000000
8	taco team	\n	$2a$10$0000000000000000000000000000000000000000
9	d0n't ph34r th3 r34p3r	\n	$2a$10$0000000000000000000000000000000000000000
10	themightyoctopus	\n	$2a$10$0000000000000000000000000000000000000000
11	clickaroundandfindout	\n	$2a$10$0000000000000000000000000000000000000000
12	ogw	\n	$2a$10$0000000000000000000000000000000000000000
13	hackthegibson	\n	$2a$10$0000000000000000000000000000000000000000
14	turducken2022	\n	$2a$10$0000000000000000000000000000000000000000
15	overdrinkers	\n	$2a$10$0000000000000000000000000000000000000000
16	undefined	\n	$2a$10$0000000000000000000000000000000000000000
17	overdrinkers	\n	$2a$10$0000000000000000000000000000000000000000
18	ctfbesties	\n	$2a$10$0000000000000000000000000000000000000000
19	catastrophe	\n	$2a$10$0000000000000000000000000000000000000000
20	burbsec	\n	$2a$10$0000000000000000000000000000000000000000
21	brandon murphy	\n	$2a$10$0000000000000000000000000000000000000000
22	pratumeers	\n	$2a$10$0000000000000000000000000000000000000000
24	redshirts	\n	$2a$10$0000000000000000000000000000000000000000
25	nope	\n	$2a$10$0000000000000000000000000000000000000000
26	skadoosh	\n	$2a$10$0000000000000000000000000000000000000000
27		\n	$2a$10$0000000000000000000000000000000000000000
28	realsmallmalawre	\n	$2a$10$0000000000000000000000000000000000000000
29	realsmallmalware	\n	$2a$10$0000000000000000000000000000000000000000
30	dank horse	\n	$2a$10$0000000000000000000000000000000000000000
32	null	\n	$2a$10$0000000000000000000000000000000000000000
33	does-strings-work	\n	$2a$10$0000000000000000000000000000000000000000
34	aruba threat labs	\n	$2a$10$0000000000000000000000000000000000000000
35	not_tom_pohl	\n	$2a$10$0000000000000000000000000000000000000000
36	_latestarter	\n	$2a$10$0000000000000000000000000000000000000000
38	sinnwell	\n	$2a$10$0000000000000000000000000000000000000000
39	the_cult_of_rob_tracy	\n	$2a$10$0000000000000000000000000000000000000000
40	1	\n	$2a$10$0000000000000000000000000000000000000000
41	the cult of rob tracey	\n	$2a$10$0000000000000000000000000000000000000000
43	pec@t	\n	$2a$10$0000000000000000000000000000000000000000
44	secbad	\n	$2a$10$0000000000000000000000000000000000000000
45	aask	\n	$2a$10$0000000000000000000000000000000000000000
46	networkgeek	\n	$2a$10$0000000000000000000000000000000000000000
47	latetoparty	\n	$2a$10$0000000000000000000000000000000000000000
\.


--
-- name: attachments_id_seq; type: sequence set; schema: public; owner: postgres
--

select pg_catalog.setval('public.attachments_id_seq', 41, true);


--
-- Name: flags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.flags_id_seq', 130, true);


--
-- Name: ssh_keys_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ssh_keys_id_seq', 59, true);


--
-- Name: submissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.submissions_id_seq', 652, true);


--
-- Name: teams_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teams_id_seq', 47, true);


--
-- Name: attachments attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);


--
-- Name: flags flags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flags
    ADD CONSTRAINT flags_pkey PRIMARY KEY (id);


--
-- Name: ssh_keys ssh_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ssh_keys
    ADD CONSTRAINT ssh_keys_pkey PRIMARY KEY (id);


--
-- Name: submissions submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);


--
-- Name: teams teams_name_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_name_unique UNIQUE (name);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: v_flag_info _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.v_flag_info AS
 SELECT f.name,
    f.id,
    count(vs.team_id) AS solves,
    array_agg(t.name) AS teams
   FROM ((public.flags f
     LEFT JOIN public.v_solves vs ON ((f.id = vs.flag_id)))
     LEFT JOIN public.teams t ON ((vs.team_id = t.id)))
  GROUP BY f.id;


--
-- Name: attachments attachments_flag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT attachments_flag_id_fkey FOREIGN KEY (flag_id) REFERENCES public.flags(id);


--
-- Name: flags flag_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flags
    ADD CONSTRAINT flag_parent_fkey FOREIGN KEY (parent) REFERENCES public.flags(id);


--
-- Name: ssh_keys ssh_keys_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ssh_keys
    ADD CONSTRAINT ssh_keys_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: submissions submissions_team_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT submissions_team_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: FUNCTION submit2(team_id integer, submission text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.submit2(team_id integer, submission text) TO bbs;


--
-- Name: TABLE attachments; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.attachments TO bbs;


--
-- Name: COLUMN flags.id; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(id) ON TABLE public.flags TO bbs;


--
-- Name: COLUMN flags.visible; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(visible) ON TABLE public.flags TO bbs;


--
-- Name: COLUMN flags.enabled; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(enabled) ON TABLE public.flags TO bbs;


--
-- Name: COLUMN flags.name; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(name) ON TABLE public.flags TO bbs;


--
-- Name: COLUMN flags.description; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(description) ON TABLE public.flags TO bbs;


--
-- Name: COLUMN flags.points; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(points) ON TABLE public.flags TO bbs;


--
-- Name: COLUMN flags.solvable; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(solvable) ON TABLE public.flags TO bbs;


--
-- Name: COLUMN flags.parent; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(parent) ON TABLE public.flags TO bbs;


--
-- Name: TABLE ssh_keys; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.ssh_keys TO bbs;


--
-- Name: COLUMN submissions.id; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(id) ON TABLE public.submissions TO bbs;


--
-- Name: TABLE teams; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.teams TO bbs;


--
-- Name: TABLE v_flag_info; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.v_flag_info TO bbs;


--
-- Name: TABLE v_solves; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.v_solves TO bbs;


--
-- Name: TABLE v_scoreboard; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.v_scoreboard TO bbs;


--
-- Name: TABLE v_submission_count; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.v_submission_count TO bbs;


--
-- Name: TABLE v_submission_meta; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.v_submission_meta TO bbs;


--
-- Name: TABLE v_team_flags; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.v_team_flags TO bbs;


--
-- Name: TABLE v_team_info; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.v_team_info TO bbs;


--
-- Name: TABLE v_valid_submissions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.v_valid_submissions TO bbs;


--
-- Name: v_solves; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.v_solves;


--
-- PostgreSQL database dump complete
--

