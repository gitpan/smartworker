#  SmartWorker, an Application Framework
#  Copyright (1999) HBE Software Inc.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#--------------------------------------------------------------------
# ContactManager::Text
#--------------------------------------------------------------------
# $Id: Text.pm,v 1.6 1999/11/15 18:17:32 gozer Exp $
#--------------------------------------------------------------------

package SW::App::ContactManager::Text;

use strict;
use vars qw(@ISA);

use SW::Language;

@ISA = qw(SW::Language Exporter);

sub new
{
	my $classname=shift;
	my $self=$classname->SUPER::new(@_);
	bless($self,$classname);

   $self->{VARIANT_LIST} = [ "en", "fr", "es"];
	$self->{STRING_TABLE} = {
		"menuHeader"	=>	{
				"en"	=>	"Contact List Management",
				"fr"	=>	"Gestion de la liste de contacts",
				"es"	=>	"Gerencia De la Lista Del Contacto",
			},
		"menuLogOut"	=>	{
				"en"	=> 	"Quit",
				"fr"	=>	"Quitter",
				"es"	=>	"Salido",
			},
		"menuWelcome"	=>	{
				"en"	=>	"Welcome",
				"fr"	=>	"Bienvenue",
				"es"	=>	"Bienvenido",
			},
		"menuList"	=>	{
				"en"	=>	"List",
				"fr"	=>	"Liste",
				"es"	=>	"Lista",
			},
		"menuLoadList"	=>	{
				"en"	=>	"Load selected list",
				"fr"	=>	"Charger la liste sélectionnée",
				"es"	=>	"Cargue la lista",
			},
		"menuAddNewCard"	=>	{
				"en"	=>	"Add",
				"fr"	=>	"Ajouter",
				"es"	=>	"Agreguar",
			},
		"menuCreateList"	=>	{
				"en"	=>	"Create a new list",
				"fr"	=>	"Créer une nouvelle liste",
				"es"	=>	"Nueva lista",
			},
		"menuContactsToShow"	=>	{
				"en"	=>	"Contacts to show",
				"fr"	=>	"Contacts à afficher",
			},
		"menuPhone"	=>	{
				"en"	=>	"Phone number",
				"fr"	=>	"Numéro de téléphone",
				"es"	=>	"Número de teléfono",
			},
		"menuEmail"	=>	{
				"en"	=>	"E-mail address",
				"fr"	=>	"Courriel",
				"es"	=>	"E-mail",
			},
		"menuSendEmail"	=>	{
				"en"	=>	"Send e-mail",
				"fr"	=>	"Envoyer Courriel",
			},
		"menuNoContact"	=> {
				"en"	=> 	"There is no contact in this list",
				"fr"	=> 	"Il n'y a pas de contact dans cette liste",
			},
		"menuNoList"	=> {
				"en"	=> 	"There is no list for this user",
				"fr"	=> 	"Il n'y a pas de liste pour cet usager",
			},
		"menuShowing"	=> {
				"en"	=> 	"Showing",
				"fr"	=> 	"Affichage",
			},
		"menuOf"	=> 	{
				"en"	=> 	"of",
				"fr"	=> 	"de",
			},
		"menuLangOptions"	=>	{
				"en"	=>	"Language",
				"fr"	=>	"Langue",
				"es"	=>	"Language",
			},
		"menuDeleteList"	=> {
			"en"	=> "Delete selected list",
			"fr"	=> "Supprimer la liste sélectionnée",
			"es"
		},		
		"addingCardMenu"	=> {
				"en" 	=> 	"Adding a new contact",
				"fr" 	=> 	"Ajout d'un nouveau contact",
			},
		"editingCardMenu"	=> {
				"en" 	=> 	"Editing a contact",
				"fr" 	=> 	"Édition d'un contact",
			},

		"vCardGeneralInformation"	=> {
				"en" 	=> 	"General information",
				"fr" 	=> 	"Information générale",
			},
		"vCard::name::prefix"	=>	{
				"en"	=>	"Prefix",
				"fr"	=>	"Préfixe",
			},
		"vCard::name::first"	=>	{
				"en"	=>	"First name",
				"fr"	=>	"Prénom",
				"es"	=>	"Nombre",
			},
		"vCard::name::middle"	=> {
				"en" 	=> 	"Middle Name",
				"fr" 	=> 	"Nom milieu",
			},
		"vCard::name::last"	=>	{
				"en"	=>	"Last name",
				"fr"	=>	"Nom",
				"es"	=>	"Pasado nombre",
			},
		"vCard::name::suffix"	=>	{
				"en"	=>	"Suffix",
				"fr"	=>	"Suffixe",
			},
		"vCard::nickname"	=> {
				"en" 	=> 	"Nicknames",
				"fr" 	=> 	"Surnoms",
			},
		"vCard::photo"	=> {
				"en" 	=> 	"URL of photo",
				"fr" 	=> 	"URL d'une photo",
			},
		"vCard::birthday"	=> {
				"en" 	=> 	"Birthday (yyyy-mm-dd)",
				"fr" 	=> 	"Date de naissance (yyyy-mm-dd)",
			},

		"vCardAddressInformation"	=> {
				"en" 	=> 	"Addresses",
				"fr" 	=> 	"Adresses",
			},
		"vCard::address::type" 	=> {
				"en" 	=> 	"Type of address",
				"fr" 	=> 	"Type d'adresse",
			},
		"vCard::address::name" 	=> {
				"en" 	=> 	"Name",
				"fr" 	=> 	"Nom",
			},
		"vCard::address::street" 	=> {
				"en" 	=> 	"Address",
				"fr" 	=> 	"Adresse",
			},
		"vCard::address::locale"	=> {
				"en" 	=> 	"City",
				"fr" 	=> 	"Ville",
			},
		"vCard::address::region"	=> {
				"en" 	=> 	"Province/State",
				"fr" 	=> 	"Province/État",
			},
		"vCard::address::code"	=> {
				"en" 	=> 	"Postal/ZIP code",
				"fr" 	=> 	"Code postal/ZIP",
			},
		"vCard::address::country"	=> {
				"en" 	=> 	"Country",
				"fr" 	=> 	"Pays",
			},
		"vCardPhoneInformation"	=> {
				"en" 	=> 	"Phone numbers",
				"fr" 	=> 	"Numéros de téléphone",
			},
		"vCard::telephone::type"	=> {
				"en" 	=> 	"Phone type",
				"fr" 	=> 	"Type de téléphone",
			},
		"vCard::telephone::number"	=> {
				"en" 	=> 	"Phone number",
				"fr" 	=> 	"Numéro de téléphone",
			},
		"vCardEmailInformation"	=> {
				"en" 	=> 	"Email address information",
				"fr" 	=> 	"Information d'addresses de courrier électronique",
			},
		"vCard::email::type"	=> {
				"en" 	=> 	"Type of email address",
				"fr" 	=> 	"Type d'adresse de courrier électronique",
			},
		"vCard::email::value"	=> {
				"en" 	=> 	"Email address",
				"fr" 	=> 	"Courriel",
			},
		"vCard::mailer"	=> {
				"en" 	=> 	"Name of mailer",
				"fr" 	=> 	"Nom du logiciel de courrier électronique",
			},
		"vCardOtherInformation"	=> {
				"en" 	=> 	"Other information",
				"fr" 	=> 	"Autre information",
			},
		"vCard::tz"	=> {
				"en" 	=> 	"Timezone",
				"fr" 	=> 	"Fuseau horaire",
			},
		"vCard::geo"	=> {
				"en" 	=> 	"Geographic location",
				"fr" 	=> 	"Localisation géographique",
			},
		"vCard::title"	=> {
				"en" 	=> 	"Title",
				"fr" 	=> 	"Titre",
			},
		"vCard::role"	=> {
				"en" 	=> 	"Organization role",
				"fr" 	=> 	"Rôle organisationnel",
			},
		"vCard::logo"	=> {
				"en" 	=> 	"URL of logo",
				"fr" 	=> 	"URL du ogo",
			},
		"vCard::org"	=> {
				"en" 	=> 	"Organization",
				"fr" 	=> 	"Organisation",
			},
		"vCard::categories"	=> {
				"en" 	=> 	"Categories",
				"fr" 	=> 	"Catégories",
			},
		"vCard::note"	=> {
				"en" 	=> 	"Note",
				"fr" 	=> 	"Note",
			},
		"vCard::sound"	=> {
				"en" 	=> 	"URL of sound file",
				"fr" 	=> 	"URL d'un fichier sonore",
			},
		"vCard::key"	=> {
				"en" 	=> 	"Public key",
				"fr" 	=> 	"Clé publique",
			},
		"vCard::URL"	=> {
				"en" 	=> 	"Internet sites",
				"fr" 	=> 	"Sites Internet",
			},
		"optionDelete"	=>	{
				"en"	=>	"Delete",
				"fr"	=>	"Effacer",
				"es"	=>	"Suprimir",
			},
		"optionSave"	=> {
				"en" 	=> 	"Save",
				"fr" 	=> 	"Sauvegarder",
			},
		"optionCancel"	=> {
				"en" 	=> 	"Cancel",
				"fr" 	=> 	"Annuler",
			},
		"optionDone"	=> {
				"en"	=> 	"Done",
				"fr"	=> 	"Retour",
			},
		"optionEdit"	=>	{
				"en"	=>	"Edit",
				"fr"	=>	"Modifier",
				"es"	=>	"Corrigir",
			},
		"optionMove"	=> {
			"en"	=> "Move",
			"fr"	=> "Déplacer",
		},
		"optionCreate"	=> {
			"en"	=> "Create",
			"fr"	=> "Créer",
		},
		"optionImport"	=>	{
				"en"	=>	"Import",
				"fr"	=>	"Importer",
				"es"	=>	"??Import",
			},
		"optionSelectFile"	=>	{
				"en"	=>	"Select file to upload",
				"fr"	=>	"Choisisez un fichier",
			},
		"optionGo"	=> {
			"en"	=> "GO",
			"fr"	=> "GO",
		},
		"enterNewListName"	=> {
			"en"	=> "Enter new list name",
			"fr"	=> "Entrez le nom de la nouvelle liste",
		},
		"creatingNewListTitle"	=> {
			"en"	=> "Creating a new list",
			"fr"	=> "Création d'une nouvelle liste",
		},
		"importingNewCardTitle"	=> {
			"en"	=> "Importing a vCard",
			"fr"	=> "Importation d'une contact (vCard)",
		},
		"importingPaste"	=> {
			"en"	=> "Paste vcard contents here",
			"fr"	=> "Copiez le contenu du vcard ici",
		},
		"importingUpload"	=> {
			"en"	=> "Choose a vCard file to upload",
			"fr"	=> "Envoyer un fichier pour importer",
		},
		"optionNoChecked"	=> {
			"en"	=> "You didn't check any contact",
			"fr"	=> "Vous n'avez pas sélectionné de contact",
		},
		"confirmDelete"	=> {
			"en"	=> "Confirm delete",
			"fr"	=> "Confirmez la suppression",
		},
		"checkedDelete"	=> {
			"en"	=> "Only checked items will be deleted",
			"fr"	=> "Seuls les items sélectionnés seront supprimés",
		},
		"confirmMove"	=> {
			"en"	=> "Confirm move",
			"fr"	=> "Confirmez le déplacement",
		},
		"checkedMove"	=> {
			"en"	=> "Only checked items will be moved",
			"fr"	=> "Seuls les items sélectionnés seront déplacés",
		},		
		"destList"	=> {
			"en"	=> "Move to ",
			"fr"	=> "Déplacer vers ",
		},		
	};

	return $self;
} 

# $Log: Text.pm,v $
# Revision 1.6  1999/11/15 18:17:32  gozer
# Added Liscence on pm files
#
# Revision 1.5  1999/09/26 21:17:58  gozer
# Added SW::User::AUthenChallenge for challenge-response authentication
#
# Revision 1.4  1999/09/09 18:52:30  gozer
# First Application to have been rewritten under the new Apache::Language::SW
# And it works
#
# Revision 1.3  1999/09/08 18:04:00  gozer
# Fixed empty language strings
#
# Revision 1.2  1999/09/07 16:23:19  gozer
# Fixed pod syntax errors
#
# Revision 1.1  1999/09/02 20:11:07  gozer
# New namespace convention
#
# Revision 1.6  1999/08/17 05:19:19  scott
# minor changes, added support for my import page
#
# Revision 1.5  1999/08/16 22:40:45  fhurtubi
# Small mods
#
1;

__END__

=head1 NAME

SW::App::ContactManager::Text - Text

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 PARAMETERS

=head1 AUTHOR

Jean-Francois Brousseau
HBE   krapht@hbe.ca
July 21/99

=head1 REVISION HISTORY

$Log: Text.pm,v $
Revision 1.6  1999/11/15 18:17:32  gozer
Added Liscence on pm files

Revision 1.5  1999/09/26 21:17:58  gozer
Added SW::User::AUthenChallenge for challenge-response authentication

Revision 1.4  1999/09/09 18:52:30  gozer
First Application to have been rewritten under the new Apache::Language::SW
And it works

Revision 1.3  1999/09/08 18:04:00  gozer
Fixed empty language strings

Revision 1.2  1999/09/07 16:23:19  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut
