import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations not found in context.');
    return localizations!;
  }

  bool get isFrench => locale.languageCode == 'fr';

  String get appName => isFrench ? 'Books on Wheels' : 'Books on Wheels';
  String get home => isFrench ? 'Accueil' : 'Home';
  String get order => isFrench ? 'Commande' : 'Order';
  String get cart => isFrench ? 'Panier' : 'Cart';
  String get profile => isFrench ? 'Profil' : 'Profile';
  String get retry => isFrench ? 'Réessayer' : 'Retry';
  String get save => isFrench ? 'Enregistrer' : 'Save';
  String get cancel => isFrench ? 'Annuler' : 'Cancel';
  String get post => isFrench ? 'Publier' : 'Post';
  String get continueLabel => isFrench ? 'Continuer' : 'Continue';
  String get seeAll => isFrench ? 'Voir tout' : 'See all';
  String get searchResults => isFrench ? 'Résultats de recherche' : 'Search Results';
  String get goodMorning => isFrench ? 'Bonjour !' : 'Hi, Good Morning!';
  String get featuredBookstores =>
      isFrench ? 'Librairies en vedette' : 'Featured Bookstores';
  String get categories => isFrench ? 'Catégories' : 'Categories';
  String get popularBooks => isFrench ? 'Livres populaires' : 'Popular Books';
  String get noPopularBooksAvailable =>
      isFrench ? 'Aucun livre populaire disponible' : 'No popular books available';
  String get noBooksMatchSearch =>
      isFrench ? 'Aucun livre ne correspond à votre recherche.' : 'No books match your search.';
  String get searchHint =>
      isFrench ? 'Rechercher des livres, auteurs, boutiques...' : 'Search books, authors, stores...';
  String get couldNotLoadBooks =>
      isFrench ? 'Impossible de charger les livres' : 'Could not load books';

  String get userEmail => isFrench ? 'E-mail utilisateur' : 'User Email';
  String get yourEmail => isFrench ? 'Votre e-mail' : 'Your Email';
  String get enterYourEmail => isFrench ? 'Entrez votre e-mail' : 'Enter your Email';
  String get password => isFrench ? 'Mot de passe' : 'Password';
  String get enterYourPassword =>
      isFrench ? 'Entrez votre mot de passe' : 'Enter your Password';
  String get rememberMe => isFrench ? 'Se souvenir de moi' : 'Remember me';
  String get forgotPassword =>
      isFrench ? 'Mot de passe oublié ?' : 'Forgot password?';
  String get signIn => isFrench ? 'Se connecter' : 'Sign in';
  String get signUp => isFrench ? 'S’inscrire' : 'Sign up';
  String get dontHaveAccount =>
      isFrench ? 'Vous n’avez pas de compte ?' : 'Don’t have an account?';
  String get alreadyHaveAccount =>
      isFrench ? 'Vous avez déjà un compte ?' : 'Already have an account?';
  String get signUpHere => isFrench ? 'Inscrivez-vous ici' : 'Sign Up Here';
  String get signInHere => isFrench ? 'Connectez-vous ici' : 'Sign In Here';
  String get continueWithGoogle =>
      isFrench ? 'Continuer avec Google' : 'Continue with Google';
  String get continueWithFacebook =>
      isFrench ? 'Continuer avec Facebook' : 'Continue with Facebook';
  String get googleNotConfigured =>
      isFrench ? 'La connexion Google n’est pas encore configurée.' : 'Google sign-in is not configured yet.';
  String get facebookNotConfigured =>
      isFrench ? 'La connexion Facebook n’est pas encore configurée.' : 'Facebook sign-in is not configured yet.';
  String get noInternetConnection => isFrench
      ? 'Pas de connexion Internet. Vérifiez votre réseau et réessayez.'
      : 'No internet connection. Check your network and try again.';
  String get somethingWentWrong => isFrench
      ? 'Une erreur s’est produite. Veuillez réessayer.'
      : 'Something went wrong. Please try again.';
  String get letsGetStarted =>
      isFrench ? 'Commençons !' : 'Let’s Get Started!';
  String get createAnAccount =>
      isFrench ? 'Créer un compte' : 'Create an account';
  String get userName => isFrench ? 'Nom d’utilisateur' : 'User Name';
  String get enterYourFirstName =>
      isFrench ? 'Entrez votre prénom' : 'Enter your First Name';
  String get enterYourName =>
      isFrench ? 'Entrez votre nom' : 'Enter your name';
  String get phoneNumber => isFrench ? 'Numéro de téléphone' : 'Phone Number';
  String get enterYourPhoneNumber =>
      isFrench ? 'Entrez votre numéro de téléphone' : 'Enter your phone number';
  String get enterYourAddress =>
      isFrench ? 'Entrez votre adresse' : 'Enter your address';
  String get confirmPassword =>
      isFrench ? 'Confirmer le mot de passe' : 'Confirm Password';
  String get currentPassword =>
      isFrench ? 'Mot de passe actuel' : 'Current Password';
  String get confirmNewPassword =>
      isFrench ? 'Confirmer le nouveau mot de passe' : 'Confirm New Password';
  String get enterConfirmPassword =>
      isFrench ? 'Entrez la confirmation du mot de passe' : 'Enter Confirm Password';
  String get resetPassword =>
      isFrench ? 'Réinitialiser le mot de passe' : 'Reset password';
  String get resetPasswordTitle =>
      isFrench ? 'Réinitialiser le mot de passe' : 'Reset Password';
  String get enterEmailToReceiveOtp =>
      isFrench ? 'Entrez votre e-mail pour recevoir le code OTP' : 'Enter your email to receive the OTP';
  String get sendOtp => isFrench ? 'Envoyer le code OTP' : 'Send OTP';
  String get otpSentToEmail =>
      isFrench ? 'Un code OTP a été envoyé à votre adresse e-mail.' : 'An OTP has been sent to your email address.';
  String get enterOtp => isFrench ? 'Entrer le code OTP' : 'Enter OTP';
  String get enterCompleteOtp =>
      isFrench ? 'Entrez le code OTP complet à 6 chiffres.' : 'Enter the complete 6-digit OTP.';
  String waitBeforeResendingOtp(int seconds) => isFrench
      ? 'Veuillez attendre ${seconds}s avant de renvoyer le code OTP.'
      : 'Please wait ${seconds}s before resending OTP.';
  String get newOtpSent =>
      isFrench ? 'Un nouveau code OTP a été envoyé à votre adresse e-mail.' : 'A new OTP has been sent to your email address.';
  String get sendingNewOtp =>
      isFrench ? 'Envoi d’un nouveau code OTP...' : 'Sending a new OTP...';
  String resendCodeIn(int seconds) =>
      isFrench ? 'Renvoyer le code dans ${seconds}s' : 'Resend code in ${seconds}s';
  String get canResendOtpNow =>
      isFrench ? 'Vous pouvez renvoyer le code OTP maintenant' : 'You can resend the OTP now';
  String get didntReceiveOtp =>
      isFrench ? 'Vous n’avez pas reçu le code OTP ?' : 'Didn’t Receive OTP?';
  String get resendOtp => isFrench ? 'RENVOYER LE CODE OTP' : 'RESEND OTP';
  String get verifyNow => isFrench ? 'Vérifier maintenant' : 'Verify Now';
  String get enterAndConfirmNewPassword =>
      isFrench ? 'Entrez et confirmez votre nouveau mot de passe' : 'Enter and confirm your new password';
  String get newPassword => isFrench ? 'Nouveau mot de passe' : 'New Password';
  String get passwordResetSuccessfully =>
      isFrench ? 'Mot de passe réinitialisé avec succès.' : 'Password reset successfully.';
  String get fillRequiredPasswordFields => isFrench
      ? 'Veuillez remplir tous les champs de mot de passe requis.'
      : 'Please fill in all required password fields.';
  String get newAndConfirmPasswordDoNotMatch => isFrench
      ? 'Le nouveau mot de passe et sa confirmation ne correspondent pas.'
      : 'New password and confirm password do not match.';
  String get passwordChangedSuccessfully =>
      isFrench ? 'Mot de passe modifié avec succès.' : 'Password changed successfully.';

  String get skip => isFrench ? 'Passer' : 'Skip';
  String get getStarted => isFrench ? 'Commencer' : 'Get Started';
  String get next => isFrench ? 'Suivant' : 'Next';
  String get discoverBooks => isFrench ? 'Découvrir des livres' : 'Discover Books';
  String get discoverBooksSubtitle => isFrench
      ? 'Parcourez une sélection de livres et trouvez votre prochaine lecture favorite en quelques secondes.'
      : 'Browse a curated collection and find your next favorite read in seconds.';
  String get quickDelivery => isFrench ? 'Livraison rapide' : 'Quick Delivery';
  String get quickDeliverySubtitle => isFrench
      ? 'Recevez rapidement les livres sélectionnés, de manière fiable, directement à votre porte.'
      : 'Get your selected books delivered fast, reliably, and right to your door.';
  String get trackOrders => isFrench ? 'Suivre les commandes' : 'Track Orders';
  String get trackOrdersSubtitle => isFrench
      ? 'Suivez votre commande du paiement à la livraison grâce à un suivi simple.'
      : 'Stay updated from checkout to doorstep with a simple order tracking flow.';

  String get myCart => isFrench ? 'Mon panier' : 'My Cart';
  String get yourCartIsEmpty =>
      isFrench ? 'Votre panier est vide' : 'Your cart is empty';
  String get cartEmptyMessage => isFrench
      ? 'Il semble que vous n’ayez pas encore ajouté de livres à votre panier.'
      : 'Looks like you haven\'t added any books to your cart yet.';
  String get browseBooks => isFrench ? 'Parcourir les livres' : 'Browse Books';
  String get totalPrice => isFrench ? 'Prix total' : 'Total Price';
  String get proceedToCheckout =>
      isFrench ? 'Passer au paiement' : 'Proceed to Checkout';
  String get paymentDetails =>
      isFrench ? 'Détails du paiement' : 'Payment details';
  String get checkout => isFrench ? 'Paiement' : 'Checkout';
  String get completeOrderDetails =>
      isFrench ? 'Complétez les détails de votre commande' : 'Complete your order details';
  String get name => isFrench ? 'Nom' : 'Name';
  String get address => isFrench ? 'Adresse' : 'Address';
  String get orderSummary => isFrench ? 'Récapitulatif de commande' : 'Order Summary';
  String get subtotal => isFrench ? 'Sous-total' : 'Subtotal';
  String get deliveryFee => isFrench ? 'Frais de livraison' : 'Delivery fee';
  String get total => isFrench ? 'Total' : 'Total';
  String get payment => isFrench ? 'Paiement' : 'Payment';
  String get placeOrder => isFrench ? 'Passer la commande' : 'Place Order';
  String get cartIsEmpty => isFrench ? 'Le panier est vide' : 'Cart is empty';
  String get orderConfirmed =>
      isFrench ? 'Commande confirmée' : 'Order Confirmed';
  String get orderPlacedSuccessfully =>
      isFrench ? 'Votre commande a été passée avec succès !' : 'Your order has been placed successfully!';
  String get status => isFrench ? 'Statut' : 'Status';
  String get backToHome => isFrench ? 'Retour à l’accueil' : 'Back to Home';
  String get stripe => 'Stripe';
  String get paypal => 'PayPal';

  String get myOrders => isFrench ? 'Mes commandes' : 'My Orders';
  String get all => isFrench ? 'Toutes' : 'All';
  String get pending => isFrench ? 'En attente' : 'Pending';
  String get processing => isFrench ? 'En cours' : 'Processing';
  String get picked => isFrench ? 'Récupérée' : 'Picked';
  String get delivered => isFrench ? 'Livrée' : 'Delivered';
  String get cancelled => isFrench ? 'Annulée' : 'Cancelled';
  String get failedToLoadOrders =>
      isFrench ? 'Échec du chargement des commandes' : 'Failed to load orders';
  String get noOrdersFound =>
      isFrench ? 'Aucune commande trouvée' : 'No orders found';
  String get completed => isFrench ? 'Terminée' : 'Completed';
  String get orderDetails => isFrench ? 'Détails de la commande' : 'Order Details';
  String get orderStatus => isFrench ? 'Statut de la commande' : 'Order Status';
  String get deliveryAddress =>
      isFrench ? 'Adresse de livraison' : 'Delivery Address';
  String get contactInformation =>
      isFrench ? 'Coordonnées' : 'Contact Information';
  String get orderDate => isFrench ? 'Date de commande :' : 'Order Date:';
  String get phone => isFrench ? 'Téléphone :' : 'Phone:';
  String get orderId => isFrench ? 'ID de commande :' : 'Order ID:';
  String itemsCount(int count) => isFrench ? 'Articles ($count)' : 'Items ($count)';
  String get leaveAReview =>
      isFrench ? 'Laisser un avis' : 'Leave a Review';
  String get unknownItem => isFrench ? 'Article inconnu' : 'Unknown Item';
  String itemCount(int count) => isFrench ? '$count article(s)' : '$count items';
  String get orderReceivedByStore =>
      isFrench ? 'Commande reçue par la boutique' : 'Order received by store';
  String get storePreparingOrder =>
      isFrench ? 'La boutique prépare votre commande' : 'Store is preparing your order';
  String get deliveryPartnerPickedUpOrder =>
      isFrench ? 'Le livreur a récupéré la commande' : 'Delivery partner picked up order';
  String get orderDeliveredSuccessfully =>
      isFrench ? 'Commande livrée avec succès' : 'Order delivered successfully';

  String get general => isFrench ? 'Général' : 'General';
  String get description => isFrench ? 'Description' : 'Description';
  String get noDescriptionAvailable =>
      isFrench ? 'Aucune description disponible.' : 'No description available.';
  String get noBooksFoundInCategory =>
      isFrench ? 'Aucun livre trouvé dans cette catégorie' : 'No books found in this category';
  String get showLess => isFrench ? 'Voir moins' : 'Show less';
  String get readMore => isFrench ? 'Lire plus' : 'Read more';
  String get addToCart => isFrench ? 'Ajouter au panier' : 'Add to Cart';
  String get outOfStock => isFrench ? 'Rupture de stock' : 'Out of Stock';
  String addedToCart(String title) =>
      isFrench ? '$title ajouté au panier' : '$title added to cart';
  String get addedToCartTitle =>
      isFrench ? 'Ajouté au panier' : 'Added to cart';

  String get editProfile => isFrench ? 'Modifier le profil' : 'Edit Profile';
  String get changePassword =>
      isFrench ? 'Changer le mot de passe' : 'Change Password';
  String get orderHistory => isFrench ? 'Historique des commandes' : 'Order History';
  String get aboutApp => isFrench ? 'À propos de l’application' : 'About App';
  String get privacyPolicy =>
      isFrench ? 'Politique de confidentialité' : 'Privacy Policy';
  String get termsAndConditions =>
      isFrench ? 'Conditions générales' : 'Terms & Conditions';
  String get language => isFrench ? 'Langue' : 'Language';
  String get pushNotifications =>
      isFrench ? 'Notifications push' : 'Push Notifications';
  String get logOut => isFrench ? 'Se déconnecter' : 'Log Out';
  String get chooseLanguage =>
      isFrench ? 'Choisir la langue' : 'Choose Language';
  String get english => 'English';
  String get france => 'France';
  String get unitedKingdom => isFrench ? 'Royaume-Uni' : 'United Kingdom';
  String get franceCountry => 'France';
  String get aboutAppContent => isFrench
      ? """QUI SUIS-JE ?

Bonjour, je suis Najwa, la fondatrice de Books on Wheels. J'ai créé ce projet avec une idée simple : permettre aux gens de commander leurs livres dans leurs librairies locales et de les recevoir rapidement chez eux, sans passer par les grandes plateformes.

Car au final, beaucoup commandent sur Amazon, Fnac ou Cultura surtout pour la rapidité et la praticité. Alors je me suis dit : pourquoi ne pas créer un Uber Eats du livre ? Books on Wheels est un service de livraison rapide conçu pour les librairies locales et les lecteurs qui souhaitent continuer à acheter autrement."""
      : """WHO AM I?

Hi, I'm Najwa, the founder of Books on Wheels. I created this project with a simple idea: allow people to order their books in their local bookstores and receive them quickly at home, without going through the big platforms.

Because in the end, many order on Amazon, Fnac or Cultura especially for speed and practicality. So I thought: why not create an Uber Eats of the book? Books on Wheels is a fast delivery service designed for local bookstores and readers who want to keep buying differently.""";

  String get privacyPolicyContent => isFrench
      ? """POLITIQUE DE CONFIDENTIALITÉ

1. Introduction
Books on Wheels accorde une importance particulière à la protection des données personnelles et au respect de la vie privée.
La présente Politique de Confidentialité explique quelles données sont collectées, pourquoi elles sont collectées et comment elles sont utilisées.

2. Données collectées
Books on Wheels peut collecter les informations suivantes :
• nom et prénom ;
• adresse e-mail ;
• numéro de téléphone ;
• adresse de livraison ;
• informations de commande ;
• données de navigation ;
• données de connexion ;
• informations de paiement via des prestataires sécurisés.
Books on Wheels ne stocke pas les données bancaires complètes.

3. Utilisation des données
Les données collectées sont utilisées afin de :
• gérer les commandes ;
• assurer les livraisons ;
• améliorer le service ;
• répondre aux demandes utilisateurs ;
• envoyer des informations liées au service ;
• assurer la sécurité de la Plateforme.

4. Partage des données
Certaines données peuvent être partagées avec :
• les librairies partenaires ;
• les coursiers ;
• les prestataires de paiement ;
• les prestataires techniques nécessaires au fonctionnement du service.
Books on Wheels ne revend pas les données personnelles.

5. Conservation des données
Les données sont conservées pendant la durée nécessaire au fonctionnement du service et au respect des obligations légales.

6. Sécurité
Books on Wheels met en œuvre des mesures raisonnables pour protéger les données personnelles contre les accès non autorisés, pertes ou divulgations.
Toutefois, aucun système n'étant totalement sécurisé, Books on Wheels ne peut garantir une sécurité absolue.

7. Cookies
La Plateforme peut utiliser des cookies afin :
• d'améliorer l'expérience utilisateur ;
• d'analyser l'utilisation du site ;
• de mesurer l'audience.
L'utilisateur peut gérer les cookies depuis les paramètres de son navigateur.

8. Droits des utilisateurs
Conformément au RGPD, l'utilisateur dispose des droits suivants :
• droit d'accès ;
• droit de rectification ;
• droit d'effacement ;
• droit d'opposition ;
• droit à la limitation ;
• droit à la portabilité.
Toute demande peut être adressée à : booksonwheels21000@gmail.com

9. Modification de la politique
Books on Wheels peut modifier la présente Politique de Confidentialité à tout moment.
La version la plus récente sera disponible sur la Plateforme.

MENTIONS LÉGALES
Éditeur du site : Books on Wheels
Statut juridique : micro-entreprise
Nom du responsable : EL FATTAHI Najwa
Adresse : Dijon, 21000
E-mail : booksonwheels21000@gmail.com
SIRET : 10654519700019

Contact : pour toute question concernant ce document : booksonwheels21000@gmail.com"""
      : """PRIVACY POLICY

1. Introduction
Books on Wheels places particular importance on the protection of personal data and respect for privacy.
This Privacy Policy explains what data is collected, why it is collected and how it is used.

2. Data collected
Books on Wheels can collect the following information:
• first and last name;
• email address;
• phone number;
• delivery address;
• order information;
• navigation data;
• login data;
• payment information via secure providers.
Books on Wheels does not store complete banking data.

3. Use of data
The collected data are used to:
• manage orders;
• ensure deliveries;
• improve the service;
• respond to user requests;
• send information related to the service;
• ensure the security of the Platform.

4. Data sharing
Some data can be shared with:
• partner bookstores;
• the couriers;
• payment providers;
• the technical service providers necessary for the operation of the service.
Books on Wheels does not resell personal data.

5. Data retention
The data is kept for the duration necessary for the operation of the service and compliance with legal obligations.

6. Security
Books on Wheels implements reasonable measures to protect personal data from unauthorized access, loss or disclosure.
However, since no system is completely secure, Books on Wheels cannot guarantee absolute security.

7. Cookies
The Platform may use cookies:
• to improve the user experience;
• to analyze the use of the site;
• to measure the audience.
The user can manage cookies from their browser settings.

8. User rights
According to the GDPR, the user has the following rights:
• right of access;
• right of rectification;
• right to erasure;
• right of opposition;
• right to limitation;
• right to portability.
Any request may be addressed to: booksonwheels21000@gmail.com

9. Policy changes
Books on Wheels may modify this Privacy Policy at any time.
The most recent version will be available on the Platform.

LEGAL NOTICES
Site publisher: Books on Wheels
Legal status: micro-enterprise
Manager's name: EL FATTAHI Najwa
Address: Dijon, 21000
E-mail: booksonwheels21000@gmail.com
SIRET: 10654519700019

Contact: for any questions regarding this document: booksonwheels21000@gmail.com""";

  String get termsAndConditionsContent => isFrench
      ? """CONDITIONS GÉNÉRALES D'UTILISATION (CGU)

1. Présentation de la plateforme
Le site et/ou l'application Books on Wheels (ci-après « la Plateforme ») est un service permettant la mise en relation entre :
• des clients souhaitant commander des livres ;
• des librairies partenaires ;
• des coursiers indépendants chargés des livraisons.
Books on Wheels agit en qualité d'intermédiaire technique et logistique.

2. Acceptation des conditions
L'utilisation de la Plateforme implique l'acceptation pleine et entière des présentes Conditions Générales d'Utilisation.
Tout utilisateur reconnaît avoir pris connaissance des présentes conditions avant toute utilisation du service.

3. Accès au service
La Plateforme est accessible aux personnes majeures disposant de la capacité juridique nécessaire.
Books on Wheels se réserve le droit de suspendre ou limiter l'accès au service à tout utilisateur ne respectant pas les présentes conditions.

4. Fonctionnement du service
Le client peut commander des livres auprès des librairies partenaires via la Plateforme.
Une fois la commande validée :
• la librairie prépare la commande ;
• un coursier indépendant récupère la commande ;
• la commande est livrée au client.
Les délais de livraison sont donnés à titre indicatif.
Books on Wheels ne garantit pas un délai fixe de livraison.

5. Responsabilités
5.1 Responsabilité des librairies
Les librairies partenaires sont seules responsables :
• des produits vendus ;
• de la conformité des livres ;
• des stocks affichés ;
• de la préparation des commandes.
5.2 Responsabilité des coursiers
Les coursiers sont des travailleurs indépendants responsables de leurs prestations de livraison.
Ils exercent leur activité sous leur propre responsabilité.
5.3 Responsabilité de Books on Wheels
Books on Wheels agit exclusivement comme plateforme de mise en relation.
La responsabilité de Books on Wheels ne pourra être engagée en cas :
• de retard de livraison ;
• d'erreur de préparation ;
• d'indisponibilité d'un produit ;
• de dommages indirects ;
• d'interruption temporaire du service ;
• de force majeure.
La responsabilité de Books on Wheels est en tout état de cause limitée au montant de la commande concernée.

6. Comportement des utilisateurs
Les utilisateurs s'engagent à :
• fournir des informations exactes ;
• utiliser la Plateforme de manière légale ;
• ne pas perturber le fonctionnement du service ;
• respecter les autres utilisateurs.
Books on Wheels se réserve le droit de suspendre un compte en cas d'abus ou de comportement inapproprié.

7. Propriété intellectuelle
Tous les contenus présents sur la Plateforme (logo, nom, design, textes, éléments graphiques, etc.) sont protégés par le droit de la propriété intellectuelle.
Toute reproduction ou utilisation sans autorisation est interdite.

8. Modification des conditions
Books on Wheels peut modifier les présentes CGU à tout moment.
Les utilisateurs seront informés des mises à jour via la Plateforme.

9. Droit applicable
Les présentes conditions sont soumises au droit français.
En cas de litige, les tribunaux compétents seront ceux du ressort du siège social de Books on Wheels.

CONDITIONS GÉNÉRALES DE VENTE (CGV)

1. Objet
Les présentes Conditions Générales de Vente définissent les modalités de commande, paiement et livraison proposées par Books on Wheels.

2. Services proposés
Books on Wheels propose :
• un service de mise en relation avec des librairies partenaires ;
• un service de livraison via des coursiers indépendants.

3. Commandes
Toute commande passée via la Plateforme implique l'acceptation des présentes CGV.
Une commande est considérée comme validée après confirmation du paiement.
Books on Wheels se réserve le droit de refuser une commande en cas de problème technique, suspicion de fraude ou indisponibilité du produit.

4. Prix
Les prix affichés sont indiqués en euros TTC.
Le montant total peut inclure :
• le prix du livre ;
• des frais de livraison ;
• des frais de service éventuels.
Books on Wheels se réserve le droit de modifier ses tarifs à tout moment.

5. Paiement
Le paiement s'effectue via les moyens proposés sur la Plateforme.
Le client garantit disposer des autorisations nécessaires pour utiliser le moyen de paiement choisi.
En cas de refus de paiement, la commande pourra être annulée.

6. Livraison
Les délais de livraison sont estimatifs.
Books on Wheels met en œuvre des moyens raisonnables pour assurer des livraisons rapides, sans garantie absolue de délai.
Le client doit fournir une adresse correcte et accessible.
En cas d'absence du client ou d'adresse incorrecte, la commande pourra être annulée sans remboursement intégral des frais de livraison.

7. Réclamations
Toute réclamation doit être adressée dans un délai de 48 heures après réception de la commande.
Des preuves pourront être demandées (photos, description du problème, etc.).

8. Remboursements
Les remboursements éventuels sont évalués au cas par cas.
Les frais de livraison peuvent ne pas être remboursés lorsque la prestation de livraison a été effectuée.
Books on Wheels se réserve le droit de refuser un remboursement en cas d'abus ou de fraude.

9. Limitation de responsabilité
Books on Wheels ne pourra être tenu responsable des dommages indirects liés à l'utilisation du service.
La responsabilité maximale de Books on Wheels est limitée au montant payé par le client pour la commande concernée.

10. Force majeure
Books on Wheels ne pourra être tenu responsable d'un retard ou d'une impossibilité de livraison causé par un événement indépendant de sa volonté :
• intempéries ;
• accidents ;
• grèves ;
• problèmes techniques ;
• circulation ;
• force majeure.

11. Droit applicable
Les présentes CGV sont soumises au droit français."""
      : """GENERAL TERMS OF USE (TOU)

1. Presentation of the platform
The Books on Wheels website and/or application (hereinafter referred to as "the Platform") is a service that allows for connections between:
• customers wishing to order books;
• partner bookstores;
• independent couriers in charge of deliveries.
Books on Wheels acts as a technical and logistical intermediary.

2. Acceptance of terms
The use of the Platform implies full and complete acceptance of these Terms of Use.
Any user acknowledges having read these terms before using the service.

3. Service access
The Platform is accessible to adults with legal capacity.
Books on Wheels reserves the right to suspend or limit access to the service to any user who does not comply with these conditions.

4. Operation of the service
The customer can order books from partner bookstores via the Platform.
Once the order is validated:
• the bookstore prepares the order;
• an independent courier collects the order;
• the order is delivered to the customer.
The delivery times are given for information purposes only.
Books on Wheels does not guarantee a fixed delivery time.

5. Responsibility
5.1 Responsibility of bookstores
The partner bookstores are solely responsible:
• for the products sold;
• for the conformity of the books;
• for the displayed stocks;
• for the preparation of orders.
5.2 Responsibility of couriers
The couriers are independent workers responsible for their delivery services.
They carry out their activity under their own responsibility.
5.3 Books on Wheels liability
Books on Wheels acts exclusively as a matchmaking platform.
Books on Wheels shall not be held liable in the event of:
• delivery delay;
• preparation error;
• a product being unavailable;
• indirect damage;
• temporary interruption of service;
• force majeure.
The liability of Books on Wheels is in any event limited to the amount of the relevant order.

6. User behavior
Users commit to:
• provide accurate information;
• use the Platform in a legal manner;
• not disrupt the operation of the service;
• respect other users.
Books on Wheels reserves the right to suspend an account in case of abuse or inappropriate behavior.

7. Intellectual property
All content on the Platform (logo, name, design, text, graphics, etc.) is protected by intellectual property law.
Any reproduction or use without permission is prohibited.

8. Modification of the conditions
Books on Wheels may modify these Terms of Use at any time.
Users will be informed of updates via the Platform.

9. Applicable law
These terms are subject to French law.
In the event of a dispute, the competent courts shall be those within the jurisdiction of the registered office of Books on Wheels.

GENERAL TERMS OF SALE (GTS)

1. Object
These General Terms and Conditions of Sale set out the ordering, payment and delivery methods offered by Books on Wheels.

2. Services offered
Books on Wheels offers:
• a matchmaking service with partner bookstores;
• a delivery service via independent couriers.

3. Orders
Any order placed via the Platform implies acceptance of these Terms of Sale.
An order is considered validated after payment has been confirmed.
Books on Wheels reserves the right to refuse an order in case of technical problem, suspicion of fraud or unavailability of the product.

4. Price
The prices quoted are in euros including tax.
The total amount can include:
• the price of the book;
• delivery fees;
• any service fees.
Books on Wheels reserves the right to change its prices at any time.

5. Payment
Payment is made via the methods offered on the Platform.
The customer guarantees to have the necessary permissions to use the chosen payment method.
If payment is refused, the order may be cancelled.

6. Delivery
The delivery times are estimated.
Books on Wheels uses reasonable means to ensure quick deliveries, without an absolute guarantee of lead time.
The client must provide a correct and accessible address.
In the event of the customer's absence or incorrect address, the order may be cancelled without a full refund of delivery costs.

7. Claims
Any complaint must be sent within 48 hours after receipt of the order.
Evidence may be requested (photos, description of the problem, etc.).

8. Reimbursements
Possible refunds are assessed on a case by case basis.
Delivery costs may not be refunded once the delivery service has been carried out.
Books on Wheels reserves the right to refuse a refund in case of abuse or fraud.

9. Limitation of liability
Books on Wheels cannot be held responsible for indirect damages related to the use of the service.
The maximum liability of Books on Wheels is limited to the amount paid by the customer for the relevant order.

10. Force majeure
Books on Wheels cannot be held responsible for any delay or impossibility of delivery caused by an event beyond its control:
• bad weather;
• accidents;
• strikes;
• technical problems;
• traffic;
• force majeure.

11. Applicable law
These Terms of Sale are subject to French law.""";
  String get areYouSureToLogout =>
      isFrench ? 'Êtes-vous sûr de vouloir vous déconnecter ?' : 'Are you sure to log out?';

  String get basicInfo => isFrench ? 'Informations de base' : 'Basic Info';
  String get personalInfo =>
      isFrench ? 'Informations personnelles' : 'Personal Info';
  String get saveChanges => isFrench ? 'Enregistrer' : 'Save Changes';
  String get profileUpdated => isFrench
      ? 'Profil mis à jour avec succès.'
      : 'Profile updated successfully.';
  String get chooseFromGallery =>
      isFrench ? 'Choisir dans la galerie' : 'Choose from gallery';
  String get takeAPhoto => isFrench ? 'Prendre une photo' : 'Take a photo';
  String get tapCameraToUpdateAvatar => isFrench
      ? 'Touchez l\'icône appareil photo pour changer la photo'
      : 'Tap camera icon to update avatar';
  String get yourNamePlaceholder => isFrench ? 'Votre nom' : 'Your Name';
  String get useYmdFormat =>
      isFrench ? 'Utilisez le format AAAA-MM-JJ' : 'Use YYYY-MM-DD format';
  String get ageMustBeNumber =>
      isFrench ? 'L\'âge doit être un nombre' : 'Age must be a number';
  String get fullNamePlaceholder =>
      isFrench ? 'Entrez votre nom complet' : 'Enter your full name';
  String get genderLabel => isFrench ? 'Genre' : 'Gender';
  String get genderHint =>
      isFrench ? 'homme / femme / autre' : 'male / female / other';
  String get dobLabel =>
      isFrench ? 'Date de naissance' : 'Date of Birth';
  String get ageLabel => isFrench ? 'Âge' : 'Age';
  String get enterAge => isFrench ? 'Entrez votre âge' : 'Enter age';
  String get bioLabel => isFrench ? 'Bio' : 'Bio';
  String get writeYourBio => isFrench ? 'Rédigez votre bio' : 'Write your bio';

  String get notifications => isFrench ? 'Notifications' : 'Notifications';
  String get markAllRead =>
      isFrench ? 'Tout marquer comme lu' : 'Mark all read';
  String get failedToLoadNotifications =>
      isFrench ? 'Échec du chargement des notifications' : 'Failed to load notifications';
  String get noNotificationsYet =>
      isFrench ? 'Aucune notification pour le moment' : 'No notifications yet';
  String get newLabel => isFrench ? 'Nouvelles' : 'New';
  String get earlier => isFrench ? 'Plus tôt' : 'Earlier';
  String get now => isFrench ? 'maintenant' : 'now';
  String minutesAgoShort(int minutes) => isFrench ? '${minutes}min' : '${minutes}m';
  String hoursAgoShort(int hours) => isFrench ? '${hours}h' : '${hours}h';
  String daysAgoShort(int days) => isFrench ? '${days}j' : '${days}d';

  String get writeShortReview => isFrench
      ? 'Écrivez un court avis pour aider les autres lecteurs...'
      : 'Write a short review to help fellow books lovers...';
  String get rateThisOrder =>
      isFrench ? 'Évaluez cette commande' : 'Rate this order';
  String get selectRating =>
      isFrench ? 'Veuillez sélectionner une note.' : 'Please select a rating.';
  String get reviewSubmitted =>
      isFrench ? 'Merci pour votre avis !' : 'Thanks for your review!';

  String get requiredField => isFrench ? 'Ce champ' : 'This field';
  String requiredMessage(String label) =>
      isFrench ? '$label est requis.' : '$label is required.';
  String get emailLabel => isFrench ? 'E-mail' : 'Email';
  String get enterValidEmail =>
      isFrench ? 'Entrez une adresse e-mail valide.' : 'Enter a valid email address.';
  String minLengthMessage(String label, int length) => isFrench
      ? '$label doit contenir au moins $length caractères.'
      : '$label must be at least $length characters.';
  String get valueLabel => isFrench ? 'Valeur' : 'Value';
  String get fullNameLabel => isFrench ? 'Nom complet' : 'Full name';
  String get confirmPasswordLabel =>
      isFrench ? 'Confirmation du mot de passe' : 'Confirm password';
  String get passwordsDoNotMatch =>
      isFrench ? 'Les mots de passe ne correspondent pas.' : 'Passwords do not match.';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any(
        (supported) => supported.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
