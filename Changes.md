## Revision history for DBIx-Squirrel

### 1.4.0 2024-08-27 21:00
-   **BREAKING CHANGES**
    -   Packages not subclassing DBI packages have now been renamed. The names
        are longer than the uninformative two-character names originlly given.
    -   Many routines housed under the Utils namespace have now been moved to
        namespaces that are more suitable.
-   **REFACTOR / FIX**
    -   A lot of older code refactored to make it more efficient, more clear,
        or more robust. I'm hoping this positively affects outcomes on a small
        number of CPANTs builds still having issues.
    -   Suspect some issues with database connection, but mainly with statement
        preparation, were being hidden by ignoring return values. Now checking
        these in case we're still having problems accessing statement attributes
        on a few CPANTs builds.
-   **DOCUMENTATION**
    -   Minor changes; mostly how things are named.
-   **TESTS**
    -   More unit tests added.
    -   Many tests broken by changes now fixed.
    -   All `$sth->{ParamValues}` fail on CPANTs builds using DBD::SQLite
        versions older than 1.56 because that's the first version to have the
        feature added. Updated the test code to detect the version in use and
        SKIP those checks for systems using an older DBD::SQLite. Since we
        don't use it in the non-test code, skipping is those tests is more
        than sufficient.
-   **TEST COVERAGE**
    ```
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/DBIx/Squirrel.pm      91.3   55.5   66.6  100.0    n/a   40.3   85.3
    ...DBIx/Squirrel/Iterator.pm   72.5   43.9   73.9   76.7    0.0    6.0   61.7
    ...x/Squirrel/ResultClass.pm   65.8   23.5    n/a   81.8    0.0    0.7   56.3
    ...BIx/Squirrel/ResultSet.pm   67.0   20.0    n/a   81.8    0.0    1.4   61.1
    ...ib/DBIx/Squirrel/Utils.pm   97.7  100.0  100.0   91.6    0.0    7.2   92.6
    blib/lib/DBIx/Squirrel/db.pm   53.7   25.0   33.3   85.7    0.0    0.6   47.1
    blib/lib/DBIx/Squirrel/dr.pm   84.2   50.0   33.3   90.0    0.0   40.3   67.5
    blib/lib/DBIx/Squirrel/st.pm   87.5   71.4   44.4  100.0    0.0    3.2   80.5
    Total                          75.6   46.4   60.0   86.6    0.0  100.0   66.9
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    ```

### 1.3.6 2024-08-26 23:00
-   **REFACTOR / FIX**
    -   The argument partitioning code that isolates transformations from
        bind-values has been re-written to (hopefully) avoid some of the
        complaints evident when testing under some older Perls.
    -   Much of the shitty old code in DBIx::Squirrel::util has been reworked
        and, given its importance, covered by some new and comprehensive unit
        tests.
    -   Made good on an earlier idea to rename the iterator's `execute` method
        to `start`. Within that context, it makes more sense since `execute`
        could reasonably be thought to require bind-params at all call sites,
        but that isn't always the case in the iterator code. So a different
        name made sense, and `execute` has been demoted to alias so as not
        to break anything.
-   **DOCUMENTATION**
    -   Minor updates.
-   **TESTS**
    -   Added compile test.
    -   Added some important unit tests.
    -   Monitoring test coverage now. More tests to come in forthcoming
        releases.

### 1.3.5 2024-08-26 07:40
-   Fixed a problem recently introduced into how transformation pipelines and
    arguments are partitioned.
-   Fixed the iterator execute method. It used the bleat about missing bind-
    values, but that doesn't make sense during construction when there might
    legitimately be none. Now calling execute with none of the expected 
    bind-values just effectively resets the iterator. 
-   Fixed the results code that was breaking due to a missing `no strict qw/refs/`.

### 1.3.4 2024-08-25 18:30
-   Some refactoring to improve robustness.

### 1.3.3 2024-08-25 18:15
-   Typos fixed and additions made to POD.
-   Tests no longer jump through hoops to open the SQLite test database in read-only mode. I only tried that
    to see if it would have a positive effect on tests segfaulting. I have since simplified testing a great
    deal since the rewrites, so pushing out this release to see if it mops-up a couple of red boxes on
    CPANTs.

### 1.3.2 2024-08-25 16:45
-   Fixed typos.
-   General improvements and optimisations.
-   Strawberry Perl 5.10.1.1 on MSWin32-x86-multi-thread can't seem to import DBD::SQLite::Constants ':file_open'
    because is isn't exported. Hopefully, a conditionally workaround solves the issue.
-   Strawberry Perl 5.14.4.1 on MSWin32-x86-multi-thread gives /Can't locate object method "e" via package "warnings"/
    error. Added "use diagnostics" pragma to all test code in an attempt to coax more useful information out.
-   Fixed broken iterator "buffer_size" code - manually set sizes weren't persistent.

### 1.3.1 2024-08-24 14:10
-   General code improvements.
-   Removed unnecessary imports.
-   Removed call to no longer extant iterator method from &DBIx::Squirrel::it::DESTROY.
-   Added the "count_all" method back into the iterator class, as well as ensuring that "count"
    does not affect a future call to "next".
-   Addressed build failures revealed by the CPAN Testers Matrix:
    -   Rewrote &DBIx::Squirrel::util::args_partition - failed on Perl versions <= 5.18.4;
    -   Back to using "strict" and "warnings" - Modern::Perl having some issues with a bundle "all"
        in Perl versions <= 5.14.4.
    -   Perls versions <= 5.13 do not support ${^GLOBAL_PHASE}, so used Devel::GlobalDestruction
        to work around the issue.
    -   Testing under Perls <= 5.13 seems to require "done_testing()" for each sub-test, as well
        as at the end of the test script.
    -   Testing under Perls <= 5.11 does not support sub-test. I can live without them, so
        have refactored the tests not to use them. Tests pass under Perl 5.10!
-   The seemingly bottomless pit of joy that is documentation updates. I'm pushing this out,
    knowing that there are gaps in the POD that must be filled. I want to get the remaining
    red issues on the CPANTS matrix to go green, hence the expedited release. POD gaps will
    be filled in future point releases.

### 1.3.0 2024-08-23 21:00
-   Ground-up rewrite of iterators and result-set code.
-   Ground-up rewrite and simplification of test code.
-   More documentation added. This stuff is never finished, and I'll be adding more in future!
-   A lot of refactoring and tidying up completed.

### 1.2.11 2024-08-18 13:15
-   Fixed typos.
-   Did some internal refactoring.
-   Updated t/lib/T/Constants.pm to ensure that SQLite database connections are created with
    both `sqlite_see_if_its_a_number => !!1` and `sqlite_open_flags => SQLITE_OPEN_READONLY`
    flags and re-ran tests successfully on macOS under Perl 5.28.1. Action was prompted by
    CPAN Tester report confirming Wstat 139 SEGFAULT on BSD under Perl 5.28.1; I have no way
    to replicate this build environment exactly, so I'm hoping this fixes the issue. We shall
    see. Thanks to Chris Williams (BINGOS) for the original report.

### 1.2.10 2024-08-17 17:35
-   Fixed minor typos in POD.
-   Did some internal refactoring.
-   Updated dist.ini: no longer using Dist::Zilla Readme plugin to produce README.
-   Updated st.pm: bind_param method no longer drops the third argument (bind attributes) before
    handing-off to &DBI::st::bind_value.
-   No longer quoting hash keys matching /^\w+$/.

### 1.2.9 2024-08-17 22:50
-   Reorganised the examples folder and renamed an example script.
-   Added some canned transforms.
-   Added new example script (examples/transformations/02.pl).
-   Added DBD::SQLite to test dependencies, with thanks to Slaven Rezić (SREZIC) for the alert.

### 1.2.8 2024-08-16 18:45
-   Fixed some documentation issues.
-   Removed a redundant line from sample script (examples/transformations_1.pl).

### 1.2.7 2024-08-16 18:00
-   First version, released on an unsuspecting world.

