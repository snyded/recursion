/*
**  recursive.ec - 'ESQL/C' functions required to perform equipment explosions
**  Copyright (C) 1995  David A. Snyder
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Library General Public
**  License as published by the Free Software Foundation; version
**  2 of the License.
**
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
**  Library General Public License for more details.
**
**  You should have received a copy of the GNU Library General Public
**  License along with this library; if not, write to the Free
**  Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <stdio.h>

struct web {
	long	id;
	struct web *NWebP;
};
$char	direction[2];


/*
************************************************************************
    This function builds a list of linked ids in "eqpweb".
************************************************************************
*/

build_web(arg)
int	arg;
{
	int	retval;
	long	id;

	if (arg != 2)
		fgl_fatal("eqpweb.ec", 41, -1318);

	popquote(direction, sizeof(direction));
	poplong(&id);

	retval = __build_web(id, 1);

	retint(retval);
	return(1);
}


static
__build_web(parent_id, level)
$long	parent_id;
$long	level;
{
	char	*malloc();
	int	retval;
	struct web *WebP, *SWepP;
	$long	id;
	$char	scratch[256];

	/* Allocate the first element of the linked list and NULL it */
	if ((WebP = (struct web *)malloc(sizeof(struct web ))) == NULL)
		return(-1319);
	WebP->id = (long)NULL;
	WebP->NWebP = (struct web *)NULL;

	/* Save the beginning of the linked list */
	SWepP = WebP;

	/* Build a cursor */
	if (*direction == 'U')
		sprintf(scratch, "select parent_eq_id from equipment where eq_id = %d", parent_id);
	else if (*direction == 'D')
		sprintf(scratch, "select eq_id from equipment where parent_eq_id = %d", parent_id);

	$prepare walk_stmt from $scratch;
	if (sqlca.sqlcode) {
		Free_WebP(SWepP);
		return(sqlca.sqlcode);
	}
	$declare walk_curs cursor for walk_stmt;
	if (sqlca.sqlcode) {
		Free_WebP(SWepP);
		return(sqlca.sqlcode);
	}

	/* Blow through the cursor and build the linked-list */
	$open walk_curs;
	$fetch walk_curs into $id;
	while (!sqlca.sqlcode) {
		if ((WebP->NWebP = (struct web *)malloc(sizeof(struct web ))) == NULL) {
			Free_WebP(SWepP);
			return(-1319);
		}
		WebP = WebP->NWebP;
		WebP->id = id;
		WebP->NWebP = NULL;
		$fetch walk_curs into $id;
	}

	/* Rewind to the beginning of the linked list */
	WebP = SWepP;

	/* Blow through the linked-list and write the data to "eqpweb" */
	while (WebP->NWebP != NULL) {
		WebP = WebP->NWebP;
		id = WebP->id;
		$insert into eqpweb values (0, $id, $direction, $level);

		if ((retval = __build_web(id, level + 1))) {
			Free_WebP(SWepP);
			return(retval);
		}
	}

	/* Free up all the allocated memory */
	Free_WebP(SWepP);

	return(0);
}


static
Free_WebP(SWepP)
struct web *SWepP;
{
	struct web *WebP;

	/* Rewind to the beginning of the linked list (for the last time) */
	WebP = SWepP;

	/* Blow through the linked-list and "free" all the elements */
	while (WebP->NWebP != NULL) {
		SWepP = WebP->NWebP;
		free(WebP);
		WebP = SWepP;
	}
	free(WebP);
}


