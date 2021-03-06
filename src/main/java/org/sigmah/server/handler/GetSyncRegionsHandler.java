package org.sigmah.server.handler;

/*
 * #%L
 * Sigmah
 * %%
 * Copyright (C) 2010 - 2016 URD
 * %%
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public
 * License along with this program.  If not, see
 * <http://www.gnu.org/licenses/gpl-3.0.html>.
 * #L%
 */

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.sigmah.server.dao.UserDatabaseDAO;
import org.sigmah.server.dispatch.impl.UserDispatch.UserExecutionContext;
import org.sigmah.server.domain.AdminLevel;
import org.sigmah.server.domain.UserDatabase;
import org.sigmah.server.handler.base.AbstractCommandHandler;
import org.sigmah.shared.command.GetSyncRegions;
import org.sigmah.shared.command.result.SyncRegion;
import org.sigmah.shared.command.result.SyncRegions;
import org.sigmah.shared.dispatch.CommandException;

import com.google.inject.Inject;

/**
 * Handler for {@link GetSyncRegions} command
 * 
 * @author Maxime Lombard (mlombard@ideia.fr)
 */
public class GetSyncRegionsHandler extends AbstractCommandHandler<GetSyncRegions, SyncRegions> {

	private final UserDatabaseDAO schemaDAO;


	@Inject
	public GetSyncRegionsHandler(UserDatabaseDAO schemaDAO) {
		this.schemaDAO = schemaDAO;
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	public SyncRegions execute(final GetSyncRegions cmd, final UserExecutionContext context) throws CommandException {

		List<UserDatabase> databases = schemaDAO.queryAllUserDatabasesAlphabetically();

		List<SyncRegion> regions = new ArrayList<SyncRegion>();
		regions.add(new SyncRegion("schema", true));
		regions.addAll(listAdminRegions(databases));
		regions.add(new SyncRegion("locations"));
		regions.addAll(listSiteRegions(databases));
		return new SyncRegions(regions);
	}

	private Collection<? extends SyncRegion> listAdminRegions(List<UserDatabase> databases) {
		List<SyncRegion> adminRegions = new ArrayList<SyncRegion>();
		Set<Integer> countriesAdded = new HashSet<Integer>();
		for (UserDatabase db : databases) {
			if (!countriesAdded.contains(db.getCountry().getId())) {
				for (AdminLevel level : db.getCountry().getAdminLevels()) {
					adminRegions.add(new SyncRegion("admin/" + level.getId(), true));
				}
				countriesAdded.add(db.getCountry().getId());
			}
		}
		return adminRegions;
	}

	/**
	 * We need a separate sync region for each OrgUnit/UserDatabase combination because we may be given permission to view
	 * data at different times.
	 */
	private Collection<? extends SyncRegion> listSiteRegions(List<UserDatabase> databases) {
		List<SyncRegion> siteRegions = new ArrayList<SyncRegion>();

		// our initial sync region manages the table schema
		siteRegions.add(new SyncRegion("site-tables"));

		// only send sync regions for database / orgUnit pairs that exist
		@SuppressWarnings("unchecked")
		List<Object[]> pairs =
				em().createQuery("SELECT DISTINCT db.id, unit.id FROM Site s JOIN s.partner unit JOIN s.activity a JOIN a.database db").getResultList();

		for (Object[] pair : pairs) {
			siteRegions.add(new SyncRegion("site/" + pair[0] + "/" + pair[1]));
		}
		return siteRegions;
	}

}
