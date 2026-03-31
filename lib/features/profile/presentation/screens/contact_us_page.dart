import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/home/presentation/screens/home_page.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/card_widgets/custom_card_template.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_user_app/features/profile/presentation/screens/faq_screen.dart';
import 'package:flutter_user_app/features/profile/presentation/screens/support_chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUs extends StatelessWidget {
  const ContactUs({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              CustomTextWidget(
                title: "Contact Us",
                subtitle:
                    "Please choose what types of support do you need and let us know.",
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                      child: CustomCardTemplate(
                    title: "Support Chat",
                    subtitle: "24x7 Online Support",
                    image: 'assets/contact_icons/support_chat.svg',
                    onTap: () {
                      navigateToPage(context, const SupportChatScreen());
                    },
                  )),
                  const SizedBox(width: 20),
                  Expanded(
                      child: CustomCardTemplate(
                          title: "Call Support",
                          subtitle: "24x7 Customer Service",
                          onTap: () async {
                            final Uri launchUri = Uri(
                              scheme: 'tel',
                              path: '+918879123444',
                            );
                            await launchUrl(launchUri);
                          },
                          image: 'assets/contact_icons/support_call.svg')),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                      child: CustomCardTemplate(
                    title: "Email Support",
                    subtitle: "Support@namoham.com",
                    image: 'assets/contact_icons/support_mail.svg',
                    onTap: () async {
                      final Uri emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: 'Support@namoham.com',
                        queryParameters: {
                          'subject': 'Support Request',
                        },
                      );
                      await launchUrl(emailLaunchUri);
                    },
                  )),
                  const SizedBox(width: 20),
                  Expanded(
                      child: CustomCardTemplate(
                          title: "FAQ",
                          subtitle: "+50 answers",
                          onTap: () {
                            navigateToPage(context, const FAQScreen());
                          },
                          image: 'assets/contact_icons/support_faq.svg')),
                ],
              ),
              const SizedBox(height: 40),
              OutlinedButton(
                  onPressed: () {
                    navigateToPage(context, HomePage());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 40,
                        ),
                        Text(
                          "Go To Home Page",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.chevron_right,
                            color: theme.colorScheme.primary),
                      ],
                    ),
                  ))
            ],
          ),
        )),
      ),
    );
  }
}
