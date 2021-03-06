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
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.persistence.Query;
import javax.persistence.TypedQuery;

import org.sigmah.server.dispatch.impl.UserDispatch.UserExecutionContext;
import org.sigmah.server.domain.OrgUnit;
import org.sigmah.server.domain.Project;
import org.sigmah.server.domain.reminder.Reminder;
import org.sigmah.server.domain.util.DomainFilters;
import org.sigmah.server.handler.base.AbstractCommandHandler;
import org.sigmah.server.handler.util.Handlers;
import org.sigmah.shared.command.GetReminders;
import org.sigmah.shared.command.result.ListResult;
import org.sigmah.shared.dispatch.CommandException;
import org.sigmah.shared.dto.reminder.ReminderDTO;

/**
 * Handler for the {@link GetReminders} command.
 * 
 * @author Raphaël Calabro (rcalabro@ideia.fr)
 * @author Maxime Lombard (mlombard@ideia.fr)
 */
public class GetRemindersHandler extends AbstractCommandHandler<GetReminders, ListResult<ReminderDTO>> {

	/**
	 * {@inheritDoc}
	 */
	@Override
	public ListResult<ReminderDTO> execute(final GetReminders cmd, final UserExecutionContext context) throws CommandException {

		final List<ReminderDTO> dtos;

		if (cmd.getProjectId() != null) {
			dtos = findProjectReminders(cmd.getProjectId(), cmd.getMappingMode(), context);

		} else {
			dtos = findAllProjectsReminders(cmd.getMappingMode(), context);
		}

		return new ListResult<>(dtos);
	}

	/**
	 * Finds the given {@code projectId} corresponding reminders.
	 * 
	 * @param projectId
	 *          The project id.
	 * @param mappingMode
	 *          The mapping mode, may be {@code null}.
	 * @param context
	 *          The user execution context.
	 * @return The reminders DTOs.
	 */
	private List<ReminderDTO> findProjectReminders(final Integer projectId, final ReminderDTO.Mode mappingMode, final UserExecutionContext context) {

		// Disable the ActivityInfo filter on Userdatabase.
		DomainFilters.disableUserFilter(em());
		
		final Query query = em().createQuery("SELECT p.remindersList.reminders FROM Project p WHERE p.id = :projectId");
		query.setParameter("projectId", projectId);

		@SuppressWarnings("unchecked")
		final List<Reminder> reminders = query.getResultList();

		return new ArrayList<ReminderDTO>(mapper().mapCollection(reminders, ReminderDTO.class, mappingMode));
	}

	/**
	 * Finds the reminders for all the projects.
	 * 
	 * @param mappingMode
	 *          The mapping mode, may be {@code null}.
	 * @param context
	 *          The user execution context.
	 * @return The reminders DTOs.
	 */
	private List<ReminderDTO> findAllProjectsReminders(final ReminderDTO.Mode mappingMode, final UserExecutionContext context) {

		final List<ReminderDTO> dtos = new ArrayList<ReminderDTO>();

		DomainFilters.disableUserFilter(em());

		// Use a set to be avoid duplicated entries.
		final Set<OrgUnit> units = new HashSet<OrgUnit>();

		// Crawl the org units hierarchy from the user root org unit.
		Handlers.crawlUnits(context.getUser(), units, true);

		// Retrieves all the corresponding org units.
		for (final OrgUnit unit : units) {

			// Builds and executes the query.
			final Query query = em().createQuery("SELECT p.remindersList.reminders FROM Project p WHERE :unit MEMBER OF p.partners");
			query.setParameter("unit", unit);

			@SuppressWarnings("unchecked")
			final List<Reminder> reminders = query.getResultList();

			for (final Reminder reminder : reminders) {

				if (reminder.getCompletionDate() != null) {
					continue; // Not completed only.
				}

                final TypedQuery<Project> fullNameQuery = em().createQuery("SELECT p FROM Project p WHERE p.remindersList = :remindersList", Project.class);
                
                fullNameQuery.setParameter("remindersList", reminder.getParentList());
               
                final ReminderDTO reminderDTO = mapper().map(reminder, new ReminderDTO(), mappingMode);
                
                Project project = fullNameQuery.getSingleResult();
                
                reminderDTO.setProjectId(project.getId());
                reminderDTO.setProjectName(project.getName());
                reminderDTO.setProjectCode(project.getFullName());
                
				dtos.add(reminderDTO);
			}
		}

		return dtos;
	}

}
